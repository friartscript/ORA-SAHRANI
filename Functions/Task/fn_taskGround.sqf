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
        - Asservissement complet des marqueurs 3D et HUD guidant le joueur directement
          vers les cibles en mouvement (visibleIn3D = true + Draw3D).
        - Ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_ground_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès
*/

params [
    ["_taskID", format ["task_ground_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]],
    ["_totalOrders", 0, [0]]
];

if (_totalOrders <= 0) then {
    _totalOrders = missionNamespace getVariable ["ORA_totalSortiesCount", missionNamespace getVariable ["ORA_selectedMissionsCount", 1]];
};

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

// Ordre radio Overlord via TTS
private _radioOrder = format [localize "STR_ORA_Task_Ground_Order", _gridStr];
["OVERLORD", _radioOrder, "STR_ORA_Task_Ground_Order"] call ORA_fnc_radioMsg;

// =============================================================================
// 4. CATALOGUES DES UNITÉS ET BLINDÉS (INFO_ENNEMIS.md)
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

// Ordre de déplacement du convoi ennemi vers la position d'embuscade alliée (>= 950m)
private _wpEnemyMove = _enemyVehGroup addWaypoint [_destPos, 0];
_wpEnemyMove setWaypointType "MOVE";
_wpEnemyMove setWaypointSpeed "NORMAL";
_wpEnemyMove setWaypointBehaviour "AWARE";
_wpEnemyMove setWaypointFormation "COLUMN";

private _wpEnemySAD = _enemyVehGroup addWaypoint [_destPos, 60];
_wpEnemySAD setWaypointType "SAD";

// =============================================================================
// 6. UNITÉS ALLIÉES RACS ATTENDANT AVEC LEURS ARMES À LA DESTINATION (>= 950m)
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

// Déclenchement automatique du fumigène vert allié dès que les ennemis approchent
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
// 7. GESTION SÉQUENTIELLE STRICTE : UNE TÂCHE APRÈS L'AUTRE (JAMAIS ENSEMBLE)
// =============================================================================
for "_k" from 0 to ((count _targetVehicles) - 1) do {
    private _target = _targetVehicles select _k;
    private _subTaskID = if ((count _targetVehicles) > 1) then {
        format ["%1_obj_%2", _taskID, _k + 1]
    } else {
        _taskID
    };

    private _taskTitle = if ((count _targetVehicles) > 1) then {
        format ["[%1/%2] %3 (%4/%5)", _orderNum, _totalOrders, localize "STR_ORA_Task_Ground_Title", _k + 1, count _targetVehicles]
    } else {
        format ["[%1/%2] %3", _orderNum, _totalOrders, localize "STR_ORA_Task_Ground_Title"]
    };

    // Révélation impérative au joueur et activation des waypoints 3D HUD natifs
    player reveal [_target, 4];
    (group player) reveal [_target, 4];
    showWaypoints true;

    // Création et assignation de CETTE TÂCHE SEULEMENT (la suivante n'existe pas encore !)
    [
        player,
        _subTaskID,
        [localize "STR_ORA_Task_Ground_Desc", _taskTitle, ""],
        getPosATL _target,
        "ASSIGNED",
        5,
        true,
        "destroy",
        true // Marqueur 3D actif natif Arma 3
    ] call BIS_fnc_taskCreate;

    [_subTaskID, true] call BIS_fnc_taskSetAlwaysVisible;
    [_subTaskID] call BIS_fnc_taskSetCurrent;

    private _realTask = _subTaskID call BIS_fnc_taskReal;
    if (!isNull _realTask) then {
        _realTask setSimpleTaskDestination (getPosATL _target);
        _realTask setSimpleTaskAlwaysVisible true;
        player setCurrentTask _realTask;
    };

    // Enregistrement de la cible active pour l'aide au tir
    missionNamespace setVariable ["ORA_activeTaskTargets", [_target], true];

    // Suivi dynamique en temps réel jusqu'à destruction de la cible
    while { alive _target && {!isNull _target} } do {
        private _tPos = getPosATL _target;
        player reveal [_target, 4];
        (group player) reveal [_target, 4];
        [_subTaskID, _tPos] call BIS_fnc_taskSetDestination;
        private _rt = _subTaskID call BIS_fnc_taskReal;
        if (!isNull _rt) then {
            _rt setSimpleTaskDestination _tPos;
            _rt setSimpleTaskAlwaysVisible true;
        };
        sleep 0.25;
    };

    // Validation immédiate de cette sous-tâche
    [_subTaskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
    missionNamespace setVariable ["ORA_activeTaskTargets", [], true];

    if (_k < ((count _targetVehicles) - 1)) then {
        playSoundUI ["ORA_Warning_Beep", 0.6, 1.2, false];
        sleep 1.0;
    };
};

// Message radio BDA QG Overlord
["OVERLORD", localize "STR_ORA_Task_Ground_Done", "STR_ORA_Task_Ground_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche
[_createdEntities, [_enemyVehGroup, _alliedGroup], 2000] spawn ORA_fnc_taskCleanup;

true
