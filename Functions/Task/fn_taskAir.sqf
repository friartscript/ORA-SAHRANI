/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission d'interception et supériorité aérienne.
        Conforme aux spécifications :
        - Les avions ennemis apparaissent STRICTEMENT sur les marqueurs rouges :
          marker_red_0 à marker_red_7 (points d'incursion lointains en haute altitude).
        - Vitesse d'incursion élevée (~800 km/h) avec cap orienté vers le centre du théâtre.
        - Appareils issus de INFO_ENNEMIS.md (Buzzard, Gryphon, Harrier, L-39, Su-34 - C-130J exclu).
        - RÈGLE CONTRACTUELLE : Aucune infanterie au sol.
        - Se limite strictement à l'abattage des chasseurs ennemis.
        - Asservissement complet des marqueurs 3D et HUD guidant le joueur directement
          vers les cibles en vol (visibleIn3D = true + Draw3D).
        - Diffuse l'ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_air_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès
*/

params [
    ["_taskID", format ["task_air_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]],
    ["_totalOrders", 0, [0]]
];

if (_totalOrders <= 0) then {
    _totalOrders = missionNamespace getVariable ["ORA_totalSortiesCount", missionNamespace getVariable ["ORA_selectedMissionsCount", 1]];
};

if (!hasInterface) exitWith { false };

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. SÉLECTION D'UN POINT D'INCURSION PARMI LES MARQUEURS ROUGES (marker_red_0..7)
// =============================================================================
private _redMarkers = [];
for "_i" from 0 to 15 do {
    private _mrk = format ["marker_red_%1", _i];
    if (getMarkerColor _mrk != "") then {
        _redMarkers pushBack _mrk;
    };
};

if (_redMarkers isEqualTo []) exitWith {
    false
};

private _spawnMrk = selectRandom _redMarkers;
private _spawnPos = getMarkerPos _spawnMrk;

// Altitude opérationnelle de combat aérien (1800m à 2200m)
private _altitude = 1800 + (random 400);
_spawnPos set [2, _altitude];

// Cap orienté vers le centre opérationnel de Sahrani ou la position du joueur
private _centerPos = if (!isNull _plane) then { getPos _plane } else { [10000, 10000, 0] };
private _ingressDir = _spawnPos getDir _centerPos;

private _gridStr = mapGridPosition _spawnPos;

// Ordre radio Overlord via TTS
private _radioOrder = format [localize "STR_ORA_Task_Air_Order", _gridStr];
["OVERLORD", _radioOrder, "STR_ORA_Task_Air_Order"] call ORA_fnc_radioMsg;

// =============================================================================
// 3. CATALOGUE DES AVIONS DE COMBAT ENNEMIS (INFO_ENNEMIS.md - C-130J EXCLU)
// =============================================================================
private _planeClasses = [
    "I_Plane_Fighter_03_CAS_F",
    "I_Plane_Fighter_04_F"
];

if (isClass (configFile >> "CfgVehicles" >> "CUP_I_AV8B_DYN_AAF")) then {
    _planeClasses pushBack "CUP_I_AV8B_DYN_AAF";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_I_L39ZA_AAF")) then {
    _planeClasses pushBack "CUP_I_L39ZA_AAF";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_I_SU34_AAF")) then {
    _planeClasses pushBack "CUP_I_SU34_AAF";
};

// =============================================================================
// 4. APPARITION DES CHASSEURS ENNEMIS SUR LE MARQUEUR ROUGE
// =============================================================================
private _numPlanes = 1 + floor (random 2);
private _targetPlanes = [];
private _createdEntities = [];
private _enemyAirGroup = createGroup [east, true];

for "_i" from 1 to _numPlanes do {
    private _pClass = selectRandom _planeClasses;
    // Espacement en formation de combat
    private _pos = _spawnPos getPos [120 * (_i - 1), _ingressDir + 90];
    _pos set [2, _altitude + ((_i - 1) * 60)];

    private _enemyJet = createVehicle [_pClass, _pos, [], 0, "FLY"];
    _enemyJet setPosASL _pos;
    _enemyJet setDir _ingressDir;
    _enemyJet setVelocityModelSpace [0, 220, 0]; // Vitesse d'incursion rapide (~800 km/h)
    _enemyJet flyInHeight _altitude;

    _enemyJet allowDamage false;
    [_enemyJet] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _enemyJet;
    (crew _enemyJet) joinSilent _enemyAirGroup;

    _enemyJet setVariable ["ORA_isEnemy", true, true];
    _targetPlanes pushBack _enemyJet;
    _createdEntities pushBack _enemyJet;
    _createdEntities append (crew _enemyJet);
    sleep 0.15;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetPlanes, true];

// Ordre d'engagement SAD (Search and Destroy) dirigé vers le secteur opérationnel
private _wp = _enemyAirGroup addWaypoint [_centerPos, 500];
_wp setWaypointType "SAD";
_wp setWaypointSpeed "FULL";
_wp setWaypointBehaviour "COMBAT";
_wp setWaypointCombatMode "RED";

// =============================================================================
// 5. GESTION SÉQUENTIELLE STRICTE : UNE TÂCHE APRÈS L'AUTRE (JAMAIS ENSEMBLE)
// =============================================================================
for "_k" from 0 to ((count _targetPlanes) - 1) do {
    private _target = _targetPlanes select _k;
    private _subTaskID = if ((count _targetPlanes) > 1) then {
        format ["%1_obj_%2", _taskID, _k + 1]
    } else {
        _taskID
    };

    private _taskTitle = if ((count _targetPlanes) > 1) then {
        format ["[%1/%2] %3 (%4/%5)", _orderNum, _totalOrders, localize "STR_ORA_Task_Air_Title", _k + 1, count _targetPlanes]
    } else {
        format ["[%1/%2] %3", _orderNum, _totalOrders, localize "STR_ORA_Task_Air_Title"]
    };

    // Révélation impérative au joueur et activation des waypoints 3D HUD natifs
    player reveal [_target, 4];
    (group player) reveal [_target, 4];
    showWaypoints true;

    // Création et assignation de CETTE TÂCHE SEULEMENT (la suivante n'existe pas encore !)
    [
        player,
        _subTaskID,
        [localize "STR_ORA_Task_Air_Desc", _taskTitle, ""],
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

    if (_k < ((count _targetPlanes) - 1)) then {
        playSoundUI ["ORA_Warning_Beep", 0.6, 1.2, false];
        sleep 1.0;
    };
};

// Message radio BDA QG Overlord
["OVERLORD", localize "STR_ORA_Task_Air_Done", "STR_ORA_Task_Air_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche
[_createdEntities, [_enemyAirGroup], 2000] spawn ORA_fnc_taskCleanup;

true
