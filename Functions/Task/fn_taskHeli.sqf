/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe contre une force héliportée d'assaut.
        Conforme aux spécifications :
        - Les hélicoptères ennemis apparaissent STRICTEMENT sur les marqueurs oranges :
          marker_orange_0 à marker_orange_52 (secteurs terrestres au sol sur Sahrani).
        - Fait apparaître 1 à 3 hélicoptères de combat/manœuvre volant en basse altitude (40-80m).
        - Fait apparaître 5 à 15 unités d'infanterie ennemie au sol autour du marqueur.
        - Fait apparaître une escouade alliée RACS (4 à 8 soldats avec dotation INFO_EDITOR.md).
        - MOUVEMENT DYNAMIQUE : Les troupes au sol s'affrontent pendant que les hélicoptères
          patrouillent et fournissent un appui-feu à basse altitude sur le secteur.
        - Signalement visuel : fumigène vert allié pour identification CAS.
        - RÈGLE CONTRACTUELLE : La réussite se limite STRICTEMENT à l'élimination des hélicoptères.
        - Ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_heli_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès

    Exemple:
        ["task_heli_1", 1] spawn ORA_fnc_taskHeli;
*/

params [
    ["_taskID", format ["task_heli_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]]
];

if (!hasInterface) exitWith { false };

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. SÉLECTION D'UN SECTEUR TERRESTRE PARMI LES MARQUEURS ORANGES (0 à 52)
// =============================================================================
private _groundMarkers = [];

for "_i" from 0 to 52 do {
    private _mrk = format ["marker_orange_%1", _i];
    if (getMarkerColor _mrk != "") then {
        _groundMarkers pushBack _mrk;
    };
};

if (_groundMarkers isEqualTo []) then {
    for "_i" from 0 to 52 do {
        private _mrk = format ["marker_blue_%1", _i];
        if (getMarkerColor _mrk != "" && {!surfaceIsWater (getMarkerPos _mrk)}) then {
            _groundMarkers pushBack _mrk;
        };
    };
};

if (_groundMarkers isEqualTo []) exitWith {
    false
};

private _spawnMrk = selectRandom _groundMarkers;
private _clashPos = getMarkerPos _spawnMrk;
_clashPos set [2, 0];

private _gridStr = mapGridPosition _clashPos;

// =============================================================================
// 2. RATTACHEMENT OU CRÉATION DE LA TÂCHE OFFICIELLE
// =============================================================================
if (!([_taskID] call BIS_fnc_taskExists)) then {
    [
        true,
        _taskID,
        [
            localize "STR_ORA_Task_Heli_Desc",
            format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Heli_Title"],
            localize "STR_ORA_Task_Heli_Marker"
        ],
        _clashPos,
        "ASSIGNED",
        5,
        true,
        "destroy",
        false
    ] call BIS_fnc_taskCreate;
} else {
    [_taskID, _clashPos] call BIS_fnc_taskSetDestination;
    [_taskID, "ASSIGNED", true] call BIS_fnc_taskSetState;
};

// Ordre radio Overlord via TTS
private _radioOrder = format [localize "STR_ORA_Task_Heli_Order", _gridStr];
["OVERLORD", _radioOrder, "STR_ORA_Task_Heli_Order"] call ORA_fnc_radioMsg;

// =============================================================================
// 3. CATALOGUE DES HÉLICOPTÈRES ET INFANTERIE (INFO_ENNEMIS.md)
// =============================================================================
private _heliClasses = [
    "I_Heli_light_03_dynamicLoadout_F",
    "I_Heli_Transport_02_F"
];

if (isClass (configFile >> "CfgVehicles" >> "CUP_B_AH1Z_Dynamic_USMC")) then {
    _heliClasses pushBack "CUP_B_AH1Z_Dynamic_USMC";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_I_AH1Z_AAF")) then {
    _heliClasses pushBack "CUP_I_AH1Z_AAF";
};

private _infantryClasses = [
    "I_soldier_F",
    "I_Soldier_AR_F",
    "I_Soldier_GL_F",
    "I_Soldier_M_F",
    "I_Soldier_LAT_F",
    "I_Soldier_AT_F",
    "I_Soldier_AA_F",
    "I_medic_F",
    "I_Soldier_SL_F",
    "I_Soldier_TL_F",
    "I_Sharpshooter_F",
    "I_Soldier_lite_F"
];

private _approachDir = random 360;

// =============================================================================
// 4. CIBLES PRIORITAIRES : 1 À 3 HÉLICOPTÈRES EN VOL BASSE ALTITUDE (40-80M)
// =============================================================================
private _numHelis = 1 + floor (random 3);
private _targetHelis = [];
private _createdEntities = [];
private _enemyHeliGroup = createGroup [east, true];

for "_i" from 1 to _numHelis do {
    private _hClass = selectRandom _heliClasses;
    private _hPos = _clashPos getPos [80 * _i, _approachDir + (_i * 45)];
    private _hAlt = 45 + (random 35);
    _hPos set [2, _hAlt];

    private _heli = createVehicle [_hClass, _hPos, [], 0, "FLY"];
    _heli setPosASL _hPos;
    _heli setDir (random 360);
    _heli flyInHeight _hAlt;
    _heli setVelocityModelSpace [0, 45, 0];

    _heli allowDamage false;
    [_heli] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _heli;
    (crew _heli) joinSilent _enemyHeliGroup;

    _heli setVariable ["ORA_isEnemy", true, true];
    _targetHelis pushBack _heli;
    _createdEntities pushBack _heli;
    _createdEntities append (crew _heli);
    sleep 0.15;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetHelis, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetHelis isNotEqualTo []) then { _targetHelis select 0 } else { objNull };

if (!isNull _currentTracked) then {
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_air";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Heli_Marker"]);
};

// Gestion multi-objectifs : si 2 objectifs ou plus, créer des sous-tâches dédiées
private _objTaskData = [];
if ((count _targetHelis) >= 2) then {
    for "_k" from 0 to ((count _targetHelis) - 1) do {
        private _tHeli = _targetHelis select _k;
        private _objID = format ["%1_obj_%2", _taskID, _k + 1];
        private _objTitle = format ["%1 %2 : %3", localize "STR_ORA_Task_Objective", _k + 1, localize "STR_ORA_Task_Heli_Marker"];
        private _objDesc = format ["%1 (%2 %3)", localize "STR_ORA_Task_Heli_Desc", localize "STR_ORA_Task_Objective", _k + 1];
        private _objState = if (_k == 0) then { "ASSIGNED" } else { "CREATED" };

        [
            true,
            [_objID, _taskID],
            [_objDesc, _objTitle, ""],
            _tHeli,
            _objState,
            5,
            (_k == 0),
            "destroy",
            false
        ] call BIS_fnc_taskCreate;

        _objTaskData pushBack [_tHeli, _objID, false];
    };
    [format ["%1_obj_1", _taskID]] call BIS_fnc_taskSetCurrent;
} else {
    if (!isNull _currentTracked) then {
        [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    };
};

// Waypoints de patrouille et appui-feu pour les hélicoptères au-dessus du secteur
for "_w" from 1 to 4 do {
    private _wpHeliPos = _clashPos getPos [250 + (_w * 100), _w * 90];
    private _wpHeli = _enemyHeliGroup addWaypoint [_wpHeliPos, 0];
    _wpHeli setWaypointType "SAD";
    _wpHeli setWaypointSpeed "NORMAL";
    _wpHeli setWaypointBehaviour "COMBAT";
    _wpHeli setWaypointCombatMode "RED";
    if (_w == 4) then {
        _wpHeli setWaypointType "CYCLE";
    };
};

// =============================================================================
// 5. TROUPES ENNEMIES AU SOL AUTOUR DU MARQUEUR ORANGE
// =============================================================================
private _enemySpawnPos = _clashPos getPos [200 + random 80, _approachDir + 180];
_enemySpawnPos set [2, 0.1];

private _numEnemyInf = 5 + floor (random 11);
private _enemyInfGroup = createGroup [east, true];

for "_i" from 1 to _numEnemyInf do {
    private _iClass = selectRandom _infantryClasses;
    private _iPos = _enemySpawnPos getPos [4 + random 25, random 360];
    _iPos set [2, 0.1];

    private _unit = _enemyInfGroup createUnit [_iClass, _iPos, [], 0, "CAN_COLLIDE"];
    _unit setPosATL _iPos;

    _unit allowDamage false;
    [_unit] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    _createdEntities pushBack _unit;
    sleep 0.05;
};

private _wpEnemyInf = _enemyInfGroup addWaypoint [_clashPos, 30];
_wpEnemyInf setWaypointType "SAD";
_wpEnemyInf setWaypointSpeed "NORMAL";
_wpEnemyInf setWaypointBehaviour "AWARE";

// =============================================================================
// 6. FORCES ALLIÉES RACS DÉPLOYÉES SUR LE SECTEUR
// =============================================================================
private _alliedSpawnPos = _clashPos getPos [180 + random 60, _approachDir];
_alliedSpawnPos set [2, 0.1];

private _numAllies = 4 + floor (random 5);
private _alliedGroup = createGroup [independent, true];

for "_i" from 1 to _numAllies do {
    private _aClass = selectRandom _infantryClasses;
    private _aPos = _alliedSpawnPos getPos [4 + random 20, random 360];
    _aPos set [2, 0.1];

    private _ally = _alliedGroup createUnit [_aClass, _aPos, [], 0, "CAN_COLLIDE"];
    _ally setPosATL _aPos;

    _ally allowDamage false;
    [_ally] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    [_ally] call ORA_fnc_applyRACSLoadout;

    _createdEntities pushBack _ally;
    sleep 0.05;
};

// Présence alliée renforcée si l'option est cochée dans le menu principal
if (missionNamespace getVariable ["ORA_setting_alliedPresence", false]) then {
    private _alliedVeh = createVehicle ["I_MRAP_03_hmg_F", _alliedSpawnPos, [], 0, "NONE"];
    _alliedVeh setDir (_approachDir + 180);
    _alliedVeh allowDamage false;
    [_alliedVeh] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };
    createVehicleCrew _alliedVeh;
    (crew _alliedVeh) joinSilent _alliedGroup;
    _createdEntities pushBack _alliedVeh;
    _createdEntities append (crew _alliedVeh);
};

private _wpAlly = _alliedGroup addWaypoint [_clashPos, 20];
_wpAlly setWaypointType "GUARD";
_wpAlly setWaypointSpeed "NORMAL";
_wpAlly setWaypointBehaviour "AWARE";

// Fumigène vert allié pour identification CAS dès l'approche
[_alliedGroup, _clashPos] spawn {
    params ["_grp", "_target"];
    waitUntil {
        sleep 2;
        ({ alive _x } count (units _grp) == 0) || {((leader _grp) distance _target) < 150}
    };
    if ({ alive _x } count (units _grp) > 0) then {
        private _smokePos = getPosATL (leader _grp);
        createVehicle ["SmokeShellGreen", _smokePos, [], 0, "NONE"];
    };
};

// =============================================================================
// 7. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
if (_objTaskData isNotEqualTo []) then {
    private _activeIdx = 0;
    private _activeObjTask = _objTaskData select 0 select 1;

    while { ({ alive (_x select 0) } count _objTaskData) > 0 } do {
        {
            _x params ["_tHeli", "_tID", "_done"];
            if (!_done && {!alive _tHeli}) then {
                _x set [2, true];
                [_tID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                // Recherche et assignation immédiate de l'autre objectif !
                private _nextIdx = _objTaskData findIf { !(_x select 2) && {alive (_x select 0)} };
                if (_nextIdx != -1) then {
                    private _nextData = _objTaskData select _nextIdx;
                    _activeIdx = _nextIdx;
                    _activeObjTask = _nextData select 1;

                    [_activeObjTask, "ASSIGNED", true] call BIS_fnc_taskSetState;
                    [_activeObjTask] call BIS_fnc_taskSetCurrent;

                };
            };
        } forEach _objTaskData;

        private _curData = _objTaskData select _activeIdx;
        if (_curData select 2 || {!alive (_curData select 0)}) then {
            private _nextIdx = _objTaskData findIf { !(_x select 2) && {alive (_x select 0)} };
            if (_nextIdx != -1) then {
                _activeIdx = _nextIdx;
                _curData = _objTaskData select _activeIdx;
            };
        };

        private _curTarget = _curData select 0;
        if (!isNull _curTarget && {alive _curTarget}) then {
            _mrkName setMarkerPosLocal (getPos _curTarget);
        };

        private _livingTargets = (_objTaskData select { !(_x select 2) && {alive (_x select 0)} }) apply { _x select 0 };
        missionNamespace setVariable ["ORA_activeTaskTargets", _livingTargets, true];

        sleep 0.5;
    };
} else {
    while { ({ alive _x } count _targetHelis) > 0 } do {
        private _livingHelis = _targetHelis select { alive _x };
        if (_livingHelis isNotEqualTo []) then {
            if (isNull _currentTracked || {!alive _currentTracked}) then {
                _currentTracked = _livingHelis select 0;
                [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
            };
            if (!isNull _currentTracked && {alive _currentTracked}) then {
                _mrkName setMarkerPosLocal (getPos _currentTracked);
            };
        };
        sleep 0.5;
    };
};

// Suppression propre du marqueur tactique de suivi
deleteMarkerLocal _mrkName;

// Validation de la tâche
[_taskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
missionNamespace setVariable ["ORA_activeTaskTargets", [], true];

// Message radio BDA QG Overlord
["OVERLORD", localize "STR_ORA_Task_Heli_Done", "STR_ORA_Task_Heli_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche :
// Toutes les unités au sol (alliés, ennemis), épaves d'hélicoptères et véhicules créés
// disparaissent immédiatement si à plus de 2000m du joueur, ou dès que le joueur s'éloigne à plus de 2000m.
[_createdEntities, [_enemyHeliGroup, _enemyInfGroup, _alliedGroup], 2000] spawn ORA_fnc_taskCleanup;

true
