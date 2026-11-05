/*
    Auteur: ORA SQF Architect
    Description:
        Système équilibré et haute performance d'aide au tir des missiles et roquettes.
        Activé via l'option tactique du menu de départ (IDC 7120).
        Architecture optimisée :
        - 0.0s à 0.35s : Séparation balistique naturelle et allumage moteur sous l'aéronef.
        - 0.35s à l'impact : Poursuite d'interception par navigation proportionnelle (PN Lead Pursuit).
          Calcul prédictif du point de collision sur cibles mobiles (avions, hélicoptères, blindés, navires).
        - Limitation aérodynamique du taux de virage (G-limit progressif) garantissant un vol
          réaliste et fluide ("aide au tir opérationnelle, pas un cheat surnaturel").
        - Fusée de proximité radioélectrique (détonation terminale à moins de 7.5m des aéronefs
          et 4.0m des cibles de surface pour éliminer les ratés de tunneling moteur).
        - En cas de destruction anticipée de la cible ou de tir balistique, le projectile
          maintient une trajectoire rectiligne stable jusqu'à l'impact au sol.
    Paramètres:
        0: _plane   - L'aéronef tireur (plane_0) [Object]
        1: _enable  - Activer (true) ou désactiver (false) le système [Boolean, défaut: true]
    Retour:
        [Boolean] - true si l'état a été configuré avec succès
    Exemple:
        [plane_0, true] call ORA_fnc_weaponGuidance;
*/

params [
    ["_plane", objNull, [objNull]],
    ["_enable", true, [true]]
];

if (!hasInterface) exitWith { false };

if (isNull _plane) then {
    _plane = missionNamespace getVariable ["plane_0", objNull];
};

if (isNull _plane) exitWith { false };

// ============================================================================
// DÉSACTIVATION DU SYSTÈME
// ============================================================================
if (!_enable) exitWith {
    private _oldEH = _plane getVariable ["ORA_weaponGuidanceEH", -1];
    if (_oldEH != -1) then {
        _plane removeEventHandler ["Fired", _oldEH];
        _plane setVariable ["ORA_weaponGuidanceEH", nil];
    };
    _plane setVariable ["ORA_guidanceAssistEnabled", false, true];

    private _frameHandler = missionNamespace getVariable ["ORA_guidanceFrameHandler", -1];
    if (_frameHandler != -1) then {
        removeMissionEventHandler ["EachFrame", _frameHandler];
        missionNamespace setVariable ["ORA_guidanceFrameHandler", -1];
    };

    missionNamespace setVariable ["ORA_activeGuidedMissiles", []];
    true
};

// ============================================================================
// ACTIVATION DU SYSTÈME
// ============================================================================
private _existingEH = _plane getVariable ["ORA_weaponGuidanceEH", -1];
if (_existingEH != -1) then {
    _plane removeEventHandler ["Fired", _existingEH];
};

_plane setVariable ["ORA_guidanceAssistEnabled", true, true];
missionNamespace setVariable ["ORA_activeGuidedMissiles", []];

// Notification visuelle au pilote si présent à bord
if (vehicle player isEqualTo _plane) then {
    titleText [
        format ["<t color='#00d0ff' size='1.05'>%1</t>", localize "STR_ORA_GUIDANCE_ACTIVE"],
        "PLAIN DOWN",
        0.5,
        true,
        true
    ];
};

// ============================================================================
// FONCTION D'ACQUISITION INTELLIGENTE DE CIBLE EN SECTEUR AVANT
// ============================================================================
ORA_fnc_guidanceAcquireTarget = {
    params ["_proj", "_planeUnit"];

    private _projPos = getPosASL _proj;
    private _projVel = velocity _proj;
    private _projDir = if (vectorMagnitude _projVel > 10) then { vectorNormalized _projVel } else { vectorDir _proj };
    private _target = objNull;

    // 1. Cible formellement verrouillée par le radar / cockpit
    private _locked = assignedTarget (vehicle player);
    if (isNull _locked) then { _locked = assignedTarget _planeUnit; };
    if (!isNull _locked && {alive _locked} && {_locked != (vehicle player)}) exitWith { _locked };

    // 2. Cible laser active
    private _laser = laserTarget (vehicle player);
    if (!isNull _laser && {alive _laser}) exitWith { _laser };

    // 3. Cible visée directement sous le réticule (HUD / viseur)
    private _cur = cursorObject;
    if (isNull _cur) then { _cur = cursorTarget; };
    if (!isNull _cur && {alive _cur} && {_cur isKindOf "AllVehicles"} && {_cur != (vehicle player)}) then {
        _target = _cur;
    };
    if (!isNull _target && {alive _target}) exitWith { _target };

    // 4. Objectifs de la sortie active (Air, Blindés, Hélicos, Navires) dans le cône avant (75°)
    private _taskTargets = (missionNamespace getVariable ["ORA_activeTaskTargets", []]) select {
        !isNull _x && {alive _x} && {_x != (vehicle player)} && {
            private _dirTo = vectorNormalized ((getPosASL _x) vectorDiff _projPos);
            (_projDir vectorDotProduct _dirTo) > 0.25
        }
    };

    if (_taskTargets isNotEqualTo []) then {
        _taskTargets = [_taskTargets, [], { _proj distance _x }, "ASCEND"] call BIS_fnc_sortBy;
        _target = _taskTargets select 0;
    };
    if (!isNull _target && {alive _target}) exitWith { _target };

    // 5. Recherche étendue du véhicule hostile le plus pertinent dans le cône avant (jusqu'à 7 500 m)
    private _allVehicles = (_projPos nearEntities [["Air", "LandVehicle", "Ship"], 7500]) select {
        alive _x && 
        {_x != _planeUnit} && 
        {_x != (vehicle player)} && {
            private _dirTo = vectorNormalized ((getPosASL _x) vectorDiff _projPos);
            (_projDir vectorDotProduct _dirTo) > 0.30
        }
    };

    private _hostileVehicles = _allVehicles select {
        (_x getVariable ["ORA_isEnemy", false]) ||
        {side (group _x) isEqualTo east} ||
        {side _x isEqualTo east} ||
        {side (group _x) isEqualTo opfor} ||
        {side _x isEqualTo opfor} ||
        {!(side (group _x) in [independent, civilian, sideFriendly])}
    };

    if (_hostileVehicles isNotEqualTo []) then {
        _hostileVehicles = [_hostileVehicles, [], { _proj distance _x }, "ASCEND"] call BIS_fnc_sortBy;
        _target = _hostileVehicles select 0;
    };

    _target
};

// ============================================================================
// ÉCOUTEUR "FIRED" SUR L'AÉRONEF
// ============================================================================
private _ehId = _plane addEventHandler ["Fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

    if (isNull _projectile) exitWith {};

    // Détection des missiles, roquettes et bombes guidées
    private _pType = toLower (typeOf _projectile);
    private _isMissile = (
        _projectile isKindOf "MissileCore" || 
        _projectile isKindOf "MissileBase" || 
        _projectile isKindOf "RocketCore" || 
        _projectile isKindOf "RocketBase" || 
        _projectile isKindOf "BombCore" || 
        _projectile isKindOf "LaserBombCore" ||
        (_pType find "missile" != -1) ||
        (_pType find "bomb" != -1) ||
        (_pType find "rocket" != -1)
    );

    if (!_isMissile) exitWith {};

    // Chronométrie de la trajectoire
    private _firedTime = time;
    private _guidanceStartTime = _firedTime + 0.35; // Séparation balistique sous l'aile (0.35s)
    private _maxLifetime       = _firedTime + 35.0; // Durée de vie maximale du projectile

    // Pré-acquisition immédiate ou différée à la séparation
    private _initialTarget = [_projectile, _unit] call ORA_fnc_guidanceAcquireTarget;

    // Enregistrement : [_projectile, _planeUnit, _guidanceStartTime, _maxLifetime, _target, _lastDir, _notified]
    private _missiles = missionNamespace getVariable ["ORA_activeGuidedMissiles", []];
    _missiles pushBack [_projectile, _unit, _guidanceStartTime, _maxLifetime, _initialTarget, [0,0,0], false];
    missionNamespace setVariable ["ORA_activeGuidedMissiles", _missiles];

    // Démarrage du gestionnaire EachFrame synchrone haute précision si inactif
    private _handlerId = missionNamespace getVariable ["ORA_guidanceFrameHandler", -1];
    if (_handlerId == -1) then {
        _handlerId = addMissionEventHandler ["EachFrame", {
            private _missiles = missionNamespace getVariable ["ORA_activeGuidedMissiles", []];
            if (_missiles isEqualTo []) exitWith {
                private _id = missionNamespace getVariable ["ORA_guidanceFrameHandler", -1];
                if (_id != -1) then {
                    removeMissionEventHandler ["EachFrame", _id];
                    missionNamespace setVariable ["ORA_guidanceFrameHandler", -1];
                };
            };

            private _remaining = [];

            {
                _x params ["_proj", "_planeUnit", "_guidanceStartTime", "_maxLifetime", "_target", "_lastDir", "_notified"];

                if (!isNull _proj && {alive _proj} && {time < _maxLifetime}) then {
                    // --------------------------------------------------------
                    // 1. Phase de séparation balistique initiale (0.0s à 0.35s)
                    // --------------------------------------------------------
                    if (time < _guidanceStartTime) then {
                        _remaining pushBack _x;
                    } else {
                        // ----------------------------------------------------
                        // 2. Notification HUD pilote à l'engagement du guidage
                        // ----------------------------------------------------
                        if (!_notified) then {
                            _x set [6, true];
                            if (vehicle player isEqualTo _planeUnit) then {
                                titleText [
                                    format ["<t color='#00e5ff' size='0.95'>[GUIDANCE] %1</t>", localize "STR_ORA_GUIDANCE_ENGAGED"],
                                    "PLAIN DOWN",
                                    0.25,
                                    true,
                                    true
                                ];
                            };
                        };

                        // ----------------------------------------------------
                        // 3. Validation / rafraîchissement de la cible
                        // ----------------------------------------------------
                        if (isNull _target || {!alive _target}) then {
                            _target = [_proj, _planeUnit] call ORA_fnc_guidanceAcquireTarget;
                            _x set [4, _target];
                        };

                        private _projPos = getPosASL _proj;
                        private _vel = velocity _proj;
                        private _speed = (vectorMagnitude _vel) max 240;
                        private _currentDir = if (vectorMagnitude _vel > 10) then { vectorNormalized _vel } else { vectorDir _proj };

                        // ----------------------------------------------------
                        // 4. Guidage vers la cible (si cible acquise et active)
                        // ----------------------------------------------------
                        if (!isNull _target && {alive _target}) then {
                            private _targetPos = if (_target isKindOf "LaserTarget") then {
                                getPosASL _target
                            } else {
                                aimPos _target
                            };
                            if (_targetPos isEqualTo [0,0,0]) then { _targetPos = getPosASL _target; };

                            // Compensation de hauteur selon la nature de l'objectif
                            if (_target isKindOf "LandVehicle") then {
                                _targetPos = _targetPos vectorAdd [0, 0, 0.4];
                            };
                            if (_target isKindOf "Ship") then {
                                _targetPos = _targetPos vectorAdd [0, 0, 0.8];
                            };

                            private _dist = _projPos distance _targetPos;

                            // Fusée de proximité radioélectrique : détonation fatale assurée
                            private _proxThreshold = if (_target isKindOf "Air") then { 7.5 } else { 4.0 };
                            if (_dist < _proxThreshold) exitWith {
                                triggerAmmo _proj;
                                _proj setDamage 1;
                            };

                            // Navigation Proportionnelle (PN) : calcul du point d'impact anticipé
                            private _targetVel = velocity _target;
                            private _timeToGo = (_dist / _speed) min 3.0;
                            private _interceptPos = _targetPos vectorAdd (_targetVel vectorMultiply _timeToGo);
                            private _desiredDir = vectorNormalized (_interceptPos vectorDiff _projPos);

                            private _dot = (_currentDir vectorDotProduct _desiredDir) max -1 min 1;

                            // L'aide guide tant que la cible est dans le demi-espace avant (angle <= 90°)
                            if (_dot > 0.0) then {
                                // Taux de virage adaptatif et progressif (évite les virages irréalistes à 90°)
                                private _turnRate = if (_dist > 1500) then {
                                    0.12
                                } else {
                                    if (_dist > 500) then { 0.22 } else { 0.38 };
                                };

                                private _newDir = vectorNormalized (_currentDir vectorAdd ((_desiredDir vectorDiff _currentDir) vectorMultiply _turnRate));

                                _proj setVelocity (_newDir vectorMultiply _speed);
                                private _upVec = if (abs (_newDir select 2) > 0.95) then { [0, 1, 0] } else { [0, 0, 1] };
                                _proj setVectorDirAndUp [_newDir, _upVec];

                                _x set [5, _newDir];
                            } else {
                                // Cible passée derrière : maintien de trajectoire d'énergie
                                _proj setVelocity (_currentDir vectorMultiply _speed);
                                private _upVec = if (abs (_currentDir select 2) > 0.95) then { [0, 1, 0] } else { [0, 0, 1] };
                                _proj setVectorDirAndUp [_currentDir, _upVec];
                                _x set [5, _currentDir];
                            };

                            _remaining pushBack _x;
                        } else {
                            // ------------------------------------------------
                            // 5. Cible absente ou détruite : vol balistique pur
                            // ------------------------------------------------
                            private _flightDir = if (_lastDir isNotEqualTo [0,0,0]) then { _lastDir } else { _currentDir };

                            _proj setVelocity (_flightDir vectorMultiply _speed);
                            private _upVec = if (abs (_flightDir select 2) > 0.95) then { [0, 1, 0] } else { [0, 0, 1] };
                            _proj setVectorDirAndUp [_flightDir, _upVec];

                            _remaining pushBack _x;
                        };
                    };
                };
            } forEach _missiles;

            missionNamespace setVariable ["ORA_activeGuidedMissiles", _remaining];
        }];

        missionNamespace setVariable ["ORA_guidanceFrameHandler", _handlerId];
    };
}];

_plane setVariable ["ORA_weaponGuidanceEH", _ehId];
true
