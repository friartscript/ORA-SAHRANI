/*
    Auteur: ORA SQF Architect
    Description:
        Système d'assistance modérée au guidage d'armement (Weapon Guidance Assist).
        Activé via l'option tactique du menu de démarrage (IDC 7120).
        Après largage ou tir d'un missile, d'une bombe ou d'une roquette, un délai
        balistique strict de 5 secondes est observé. Passé ce délai, le projectile vise
        en priorité la cible de la tâche active ou l'ennemi le plus proche (véhicule
        air ou sol, même s'ils sont 2 ou plus) avec anticipation de trajectoire (lead pursuit).
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

if (isNull _plane) exitWith {
    diag_log "[ORA-GUIDANCE] [ERREUR] plane_0 est null. Impossible de configurer l'aide au guidage.";
    false
};

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
    diag_log "[ORA-GUIDANCE] Système d'assistance au guidage désactivé.";
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
diag_log "[ORA-GUIDANCE] [ACTIF] Système d'aide au guidage armé sur plane_0.";

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

// Attachement de l'écouteur d'armement "Fired"
private _ehId = _plane addEventHandler ["Fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

    if (isNull _projectile) exitWith {};

    // Filtrer les munitions éligibles : missiles, bombes et roquettes
    private _isEligible = (
        _projectile isKindOf "MissileBase" || 
        _projectile isKindOf "BombCore" || 
        _projectile isKindOf "RocketBase"
    );

    if (!_isEligible) exitWith {};

    // Routine de guidage assisté asynchrone
    [_projectile, _unit] spawn {
        params ["_projectile", "_plane"];

        // 1. Délai balistique obligatoire de 5 secondes après largage / tir
        sleep 5;

        // Si le projectile a déjà détoné ou n'existe plus
        if (isNull _projectile || {!alive _projectile}) exitWith {};

        // Fonction d'acquisition de cible prioritaire :
        // 1) Cible radar/système lockée par le pilote
        // 2) Cible désignée au laser
        // 3) Cible de la tâche en cours (la plus proche du missile même s'il y en a 2 ou plus)
        // 4) Ennemi le plus proche (véhicule air ou sol) dans un rayon de 7 000 m
        private _fn_findBestTarget = {
            params ["_proj", "_planeUnit"];

            private _best = objNull;

            // 1. Cible verrouillée par le système radar
            private _locked = assignedTarget _planeUnit;
            if (!isNull _locked && {alive _locked}) exitWith { _locked };

            // 2. Cible laser active
            private _laser = laserTarget _planeUnit;
            if (!isNull _laser && {alive _laser}) exitWith { _laser };

            // 3. Cibles assignées à la tâche en cours (même s'ils sont 2 ou plus)
            private _taskTargets = (missionNamespace getVariable ["ORA_activeTaskTargets", []]) select {
                !isNull _x && {alive _x}
            };

            if (_taskTargets isNotEqualTo []) then {
                // Trier par distance au projectile : sélectionner le plus proche
                _taskTargets = [_taskTargets, [], { _proj distance _x }, "ASCEND"] call BIS_fnc_sortBy;
                _best = _taskTargets select 0;
            };

            if (!isNull _best && {alive _best}) exitWith { _best };

            // 4. Recherche de l'ennemi le plus proche (véhicule air ou sol) même s'ils sont 2 ou plus
            private _projPos = getPosASL _proj;
            private _hostileVehicles = (_projPos nearEntities [["Air", "LandVehicle", "Ship"], 7000]) select {
                alive _x && 
                {_x != _planeUnit} && 
                {
                    (_x getVariable ["ORA_isEnemy", false]) || 
                    {side (group _x) isEqualTo east} || 
                    {side _x isEqualTo east} || 
                    {[side _planeUnit, side _x] call BIS_fnc_sideIsEnemy}
                }
            };

            if (_hostileVehicles isNotEqualTo []) then {
                // Trier par distance croissante au projectile
                _hostileVehicles = [_hostileVehicles, [], { _proj distance _x }, "ASCEND"] call BIS_fnc_sortBy;
                _best = _hostileVehicles select 0;
            };

            _best
        };

        // 2. Détermination de la cible initiale
        private _target = [_projectile, _plane] call _fn_findBestTarget;

        // Si aucune cible n'est identifiable, le projectile conserve sa trajectoire balistique standard
        if (isNull _target || {!alive _target}) exitWith {};

        // Notification d'engagement du guidage au pilote
        if (vehicle player isEqualTo _plane) then {
            titleText [
                format ["<t color='#22dd66' size='0.95'>[GUIDANCE] %1</t>", localize "STR_ORA_GUIDANCE_ENGAGED"],
                "PLAIN DOWN",
                0.35,
                true,
                true
            ];
        };

        // 3. Boucle d'assistance au guidage avec anticipation (Lead Pursuit)
        private _startTime = time;
        private _maxDuration = 25; // Durée maximale de guidage (secondes)
        private _blendRate = 0.045; // Correction progressive et réactive par pas de 35ms

        while {
            alive _projectile && 
            {(time - _startTime) < _maxDuration}
        } do {
            // Si la cible actuelle est détruite en vol, re-sélectionner instantanément
            // l'ennemi survivant le plus proche (même s'ils sont 2 ou plus)
            if (isNull _target || {!alive _target}) then {
                _target = [_projectile, _plane] call _fn_findBestTarget;
            };

            if (isNull _target || {!alive _target}) exitWith {};

            private _projPos = getPosASL _projectile;
            private _targetPos = if (_target isKindOf "LaserTarget") then {
                getPosASL _target
            } else {
                aimPos _target
            };
            if (_targetPos isEqualTo [0, 0, 0]) then { _targetPos = getPosASL _target; };

            private _dist = _projPos vectorDistance _targetPos;
            // Phase terminale libre sous 8m pour impact naturel
            if (_dist < 8) exitWith {};

            private _currentVel = velocity _projectile;
            private _currentSpeed = vectorMagnitude _currentVel;
            if (_currentSpeed < 15) exitWith {};

            // Anticipation de la position future de la cible (Lead Pursuit)
            private _leadTime = (_dist / (_currentSpeed max 50)) min 2.0;
            private _targetVel = velocity _target;
            private _predictedTargetPos = _targetPos vectorAdd (_targetVel vectorMultiply _leadTime);

            private _currentDir = vectorNormalized _currentVel;
            private _desiredDir = vectorNormalized (_predictedTargetPos vectorDiff _projPos);

            // Inflexion douce du vecteur vitesse (conservation stricte de l'énergie cinétique)
            private _newDir = vectorNormalized (_currentDir vectorAdd (_desiredDir vectorMultiply _blendRate));
            private _newVel = _newDir vectorMultiply _currentSpeed;

            _projectile setVelocity _newVel;

            // Alignement du modèle 3D sur le nouveau vecteur
            private _upVec = if (abs (_newDir select 2) > 0.95) then { [0, 1, 0] } else { [0, 0, 1] };
            _projectile setVectorDirAndUp [_newDir, _upVec];

            sleep 0.035;
        };
    };
}];

_plane setVariable ["ORA_weaponGuidanceEH", _ehId];
true
