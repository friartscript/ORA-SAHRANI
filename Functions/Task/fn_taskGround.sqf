/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe au sol (CAS / Anti-Blindés).
        Conforme aux spécifications :
        - Les missions au sol s'effectuent STRICTEMENT sur les marqueurs routiers :
          marker_orange_0 à marker_orange_52 (ou marker_blue_0 à 52 si applicable).
        - Ces marqueurs sont placés exactement sur le réseau routier de Sahrani.
        - Fait apparaître 1 à 3 véhicules blindés ennemis directement sur la route.
        - Les véhicules se déplacent en convoi le long de la route vers un autre point
          situé à MINIMUM 950 mètres.
        - À cette destination (>= 950m), des unités alliées RACS armées (lance-roquettes,
          fusils, mitrailleuses) les attendent en position défensive / embuscade.
        - Signalement visuel : fumigène vert allié (SmokeShellGreen) dès l'engagement.
        - RÈGLE CONTRACTUELLE : La réussite se limite STRICTEMENT à l'élimination des véhicules.
        - Ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_ground_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès

    Exemple:
        ["task_ground_1", 1] spawn ORA_fnc_taskGround;
*/

params [
    ["_taskID", format ["task_ground_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]]
];

if (!hasInterface) exitWith { false };

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. COLLECTE DES MARQUEURS ROUTIERS (marker_orange_0..52 ou marker_blue_0..52)
// =============================================================================
private _roadMarkers = [];

// Recherche prioritaire des marqueurs oranges (placés sur les routes dans l'éditeur)
for "_i" from 0 to 52 do {
    private _mrk = format ["marker_orange_%1", _i];
    if (getMarkerColor _mrk != "") then {
        _roadMarkers pushBack _mrk;
    };
};

// Fallback transparent si les marqueurs sont préfixés marker_blue_
if (_roadMarkers isEqualTo []) then {
    for "_i" from 0 to 52 do {
        private _mrk = format ["marker_blue_%1", _i];
        if (getMarkerColor _mrk != "" && {!surfaceIsWater (getMarkerPos _mrk)}) then {
            _roadMarkers pushBack _mrk;
        };
    };
};

if (_roadMarkers isEqualTo []) exitWith {
    false
};

// =============================================================================
// 2. CHOIX DU MARQUEUR DE DÉPART ET ALIGNEMENT EXACT SUR LA ROUTE
// =============================================================================
private _spawnMrk = selectRandom _roadMarkers;
private _spawnPos = getMarkerPos _spawnMrk;

// Repérage précis du tronçon routier au milieu du marqueur
private _nearRoads = _spawnPos nearRoads 80;
private _roadDir = random 360;

if (_nearRoads isNotEqualTo []) then {
    private _road = _nearRoads select 0;
    _spawnPos = getPosATL _road;
    private _conn = roadsConnectedTo _road;
    if (_conn isNotEqualTo []) then {
        _roadDir = _road getDir (_conn select 0);
    };
};
_spawnPos set [2, 0.1];

// =============================================================================
// 3. SÉLECTION D'UN LIEU DE DESTINATION À MINIMUM 950 MÈTRES
// =============================================================================
private _destCandidates = _roadMarkers select { ((getMarkerPos _x) distance2D _spawnPos) >= 950 };
private _destPos = [];

if (_destCandidates isNotEqualTo []) then {
    private _destMrk = selectRandom _destCandidates;
    _destPos = getMarkerPos _destMrk;
    private _nearDestRoads = _destPos nearRoads 80;
    if (_nearDestRoads isNotEqualTo []) then {
        _destPos = getPosATL (_nearDestRoads select 0);
    };
} else {
    // Si aucun marqueur n'est assez éloigné, projection à 1100m le long de l'axe routier
    _destPos = _spawnPos getPos [1100, _roadDir];
};
_destPos set [2, 0.1];

// Réajuster l'orientation du convoi vers la destination choisie
_roadDir = _spawnPos getDir _destPos;

private _gridStr = mapGridPosition _spawnPos;

// =============================================================================
// 4. RATTACHEMENT OU CRÉATION DE LA TÂCHE OFFICIELLE
// =============================================================================
if (!([_taskID] call BIS_fnc_taskExists)) then {
    [
        true,
        _taskID,
        [
            localize "STR_ORA_Task_Ground_Desc",
            format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Ground_Title"],
            localize "STR_ORA_Task_Ground_Marker"
        ],
        _spawnPos,
        "ASSIGNED",
        5,
        true,
        "destroy",
        false
    ] call BIS_fnc_taskCreate;
} else {
    [_taskID, _spawnPos] call BIS_fnc_taskSetDestination;
    [_taskID, "ASSIGNED", true] call BIS_fnc_taskSetState;
};

// Ordre radio Overlord via TTS
private _radioOrder = format [localize "STR_ORA_Task_Ground_Order", _gridStr];
["OVERLORD", _radioOrder, "STR_ORA_Task_Ground_Order"] call ORA_fnc_radioMsg;

// =============================================================================
// 5. CATALOGUES DES UNITÉS ET BLINDÉS (INFO_ENNEMIS.md)
// =============================================================================
private _vehicleClasses = [
    "I_LT_01_AA_F",
    "I_LT_01_AT_F",
    "I_LT_01_cannon_F",
    "I_APC_Wheeled_03_cannon_F",
    "I_APC_tracked_03_cannon_F",
    "I_MBT_03_cannon_F",
    "I_MRAP_03_gmg_F",
    "I_MRAP_03_hmg_F"
];

if (isClass (configFile >> "CfgVehicles" >> "CUP_I_ZSU23_Afghan_AAF")) then {
    _vehicleClasses pushBack "CUP_I_ZSU23_Afghan_AAF";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_I_ZSU23_AAF")) then {
    _vehicleClasses pushBack "CUP_I_ZSU23_AAF";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_I_M163_AAF")) then {
    _vehicleClasses pushBack "CUP_I_M163_AAF";
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

// =============================================================================
// 6. APPARITION DU CONVOI ENNEMI SUR LA ROUTE (1 À 3 VÉHICULES)
// =============================================================================
private _numVehicles = 1 + floor (random 3);
private _targetVehicles = [];
private _createdEntities = [];
private _enemyVehGroup = createGroup [east, true];

for "_i" from 1 to _numVehicles do {
    private _vClass = selectRandom _vehicleClasses;
    // Espacement propre de 25m en file indienne le long de la route
    private _vPos = _spawnPos getPos [25 * (_i - 1), _roadDir + 180];
    _vPos set [2, 0.1];

    private _veh = createVehicle [_vClass, _vPos, [], 0, "NONE"];
    _veh setDir _roadDir;
    _veh setPosATL _vPos;

    _veh allowDamage false;
    [_veh] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _veh;
    (crew _veh) joinSilent _enemyVehGroup;

    _veh setVariable ["ORA_isEnemy", true, true];
    _targetVehicles pushBack _veh;
    _createdEntities pushBack _veh;
    _createdEntities append (crew _veh);
    sleep 0.15;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetVehicles, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetVehicles isNotEqualTo []) then { _targetVehicles select 0 } else { objNull };

if (!isNull _currentTracked) then {
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_armor";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Ground_Marker"]);
};

// Gestion multi-objectifs : si 2 objectifs ou plus, créer des sous-tâches dédiées
private _objTaskData = [];
if ((count _targetVehicles) >= 2) then {
    for "_k" from 0 to ((count _targetVehicles) - 1) do {
        private _tVeh = _targetVehicles select _k;
        private _objID = format ["%1_obj_%2", _taskID, _k + 1];
        private _objTitle = format ["%1 %2 : %3", localize "STR_ORA_Task_Objective", _k + 1, localize "STR_ORA_Task_Ground_Marker"];
        private _objDesc = format ["%1 (%2 %3)", localize "STR_ORA_Task_Ground_Desc", localize "STR_ORA_Task_Objective", _k + 1];
        private _objState = if (_k == 0) then { "ASSIGNED" } else { "CREATED" };

        [
            true,
            [_objID, _taskID],
            [_objDesc, _objTitle, ""],
            _tVeh,
            _objState,
            5,
            (_k == 0),
            "destroy",
            false
        ] call BIS_fnc_taskCreate;

        _objTaskData pushBack [_tVeh, _objID, false];
    };
    [format ["%1_obj_1", _taskID]] call BIS_fnc_taskSetCurrent;
} else {
    if (!isNull _currentTracked) then {
        [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    };
};

// Ordre de déplacement du convoi ennemi vers la position d'embuscade alliée (>= 950m)
private _wpEnemyMove = _enemyVehGroup addWaypoint [_destPos, 0];
_wpEnemyMove setWaypointType "MOVE";
_wpEnemyMove setWaypointSpeed "NORMAL";
_wpEnemyMove setWaypointBehaviour "AWARE";
_wpEnemyMove setWaypointFormation "COLUMN";

private _wpEnemySAD = _enemyVehGroup addWaypoint [_destPos, 60];
_wpEnemySAD setWaypointType "SAD";

// =============================================================================
// 7. UNITÉS ALLIÉES RACS ATTENDANT AVEC LEURS ARMES À LA DESTINATION (>= 950m)
// =============================================================================
private _alliedGroup = createGroup [independent, true];
private _numAllies = 4 + floor (random 5); // 4 à 8 soldats alliés RACS armés

for "_i" from 1 to _numAllies do {
    private _aClass = selectRandom _infantryClasses;
    // Déploiement en arc défensif / couverture autour du point d'arrivée
    private _aPos = _destPos getPos [8 + random 25, random 360];
    _aPos set [2, 0.1];

    private _ally = _alliedGroup createUnit [_aClass, _aPos, [], 0, "CAN_COLLIDE"];
    _ally setPosATL _aPos;
    _ally setDir (_destPos getDir _spawnPos);

    _ally allowDamage false;
    [_ally] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    // Application contractuelle de la dotation RACS (armes, roquettes AT, munitions)
    [_ally] call ORA_fnc_applyRACSLoadout;

    _createdEntities pushBack _ally;
    sleep 0.05;
};

// Posture d'attente armée en embuscade
_alliedGroup setCombatMode "RED";
_alliedGroup setBehaviour "COMBAT";
private _wpAllyHold = _alliedGroup addWaypoint [_destPos, 15];
_wpAllyHold setWaypointType "HOLD";

// Présence alliée renforcée si l'option est cochée dans le menu principal
if (missionNamespace getVariable ["ORA_setting_alliedPresence", false]) then {
    private _alliedVehPos = _destPos getPos [15, _destPos getDir _spawnPos];
    _alliedVehPos set [2, 0.1];
    private _alliedVeh = createVehicle ["I_MRAP_03_hmg_F", _alliedVehPos, [], 0, "NONE"];
    _alliedVeh setDir (_destPos getDir _spawnPos);
    _alliedVeh allowDamage false;
    [_alliedVeh] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };
    createVehicleCrew _alliedVeh;
    (crew _alliedVeh) joinSilent _alliedGroup;
    _createdEntities pushBack _alliedVeh;
    _createdEntities append (crew _alliedVeh);
};

// Déclenchement automatique du fumigène vert allié et message radio dès que les ennemis approchent
[_alliedGroup, _targetVehicles, _destPos] spawn {
    params ["_allyGrp", "_enemyVehs", "_pos"];
    waitUntil {
        sleep 2;
        ({ alive _x } count (units _allyGrp) == 0) ||
        ({ alive _x } count _enemyVehs == 0) ||
        { (_enemyVehs select 0) distance _pos < 450 }
    };

    if ({ alive _x } count (units _allyGrp) > 0 && {({ alive _x } count _enemyVehs) > 0}) then {
        private _smokePos = getPosATL (leader _allyGrp);
        createVehicle ["SmokeShellGreen", _smokePos, [], 0, "NONE"];
    };
};

// =============================================================================
// 8. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
if (_objTaskData isNotEqualTo []) then {
    private _activeIdx = 0;
    private _activeObjTask = _objTaskData select 0 select 1;

    while { ({ alive (_x select 0) } count _objTaskData) > 0 } do {
        {
            _x params ["_tVeh", "_tID", "_done"];
            if (!_done && {!alive _tVeh}) then {
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
    while { ({ alive _x } count _targetVehicles) > 0 } do {
        private _livingVehs = _targetVehicles select { alive _x };
        if (_livingVehs isNotEqualTo []) then {
            if (isNull _currentTracked || {!alive _currentTracked}) then {
                _currentTracked = _livingVehs select 0;
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
["OVERLORD", localize "STR_ORA_Task_Ground_Done", "STR_ORA_Task_Ground_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche :
// Toutes les unités au sol et épaves créées disparaissent immédiatement si à plus de 2000m du joueur,
// ou dès que le joueur s'éloigne à plus de 2000m.
[_createdEntities, [_enemyVehGroup, _alliedGroup], 2000] spawn ORA_fnc_taskCleanup;

true
