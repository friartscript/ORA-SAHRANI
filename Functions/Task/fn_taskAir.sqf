/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission d'interception et supériorité aérienne.
        Conforme aux spécifications :
        - Fait apparaître 1 à 2 avions de combat ennemis en vol à haute altitude.
        - Appareils issus de INFO_ENNEMIS.md (Buzzard, Gryphon, Harrier, L-39, Su-34 - C-130J exclu).
        - RÈGLE CONTRACTUELLE : Aucune infanterie au sol.
        - Se limite strictement à l'abattage des chasseurs ennemis.
        - Diffuse l'ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_air_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès

    Exemple:
        ["task_air_1", 1] spawn ORA_fnc_taskAir;
*/

params [
    ["_taskID", format ["task_air_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]]
];

if (!hasInterface) exitWith { false };

diag_log format ["[ORA-TASK] [AIR] Démarrage de la tâche %1 (Sortie %2)...", _taskID, _orderNum];

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. DÉFINITION DE LA POSITION D'INTERCEPTION ET DU POINT DE SPAWN AÉRIEN
// =============================================================================
private _centerPos = getPos _plane;
private _dirToAir = random 360;
private _distAir = 7000 + (random 4000);
private _targetPos = _centerPos getPos [_distAir, _dirToAir];
_targetPos set [2, 1500];

private _gridStr = mapGridPosition _targetPos;

// =============================================================================
// 2. CRÉATION DE LA TÂCHE (BIS_fnc_taskCreate)
// =============================================================================
[
    true,
    _taskID,
    [
        localize "STR_ORA_Task_Air_Desc",
        format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Air_Title"],
        localize "STR_ORA_Task_Air_Marker"
    ],
    _targetPos,
    "AUTOASSIGNED",
    5,
    true,
    "destroy",
    false
] call BIS_fnc_taskCreate;

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
// 4. APPARITION DES CIBLES : 1 À 2 AVIONS DE CHASSE EN VOL
// =============================================================================
private _numPlanes = 1 + floor (random 2);
private _targetPlanes = [];
private _enemyAirGroup = createGroup [east, true];

for "_i" from 1 to _numPlanes do {
    private _pClass = selectRandom _planeClasses;
    private _spawnPos = _targetPos getPos [150 * _i, _dirToAir + 180];
    _spawnPos set [2, 1600 + (random 400)];

    private _enemyJet = createVehicle [_pClass, _spawnPos, [], 0, "FLY"];
    _enemyJet setDir (_dirToAir + 180);
    _enemyJet setVelocityModelSpace [0, 160, 0];

    _enemyJet allowDamage false;
    [_enemyJet] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _enemyJet;
    (crew _enemyJet) joinSilent _enemyAirGroup;

    _enemyJet setVariable ["ORA_isEnemy", true, true];
    _targetPlanes pushBack _enemyJet;
    sleep 0.2;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetPlanes, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetPlanes isNotEqualTo []) then { _targetPlanes select 0 } else { objNull };

if (!isNull _currentTracked) then {
    [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_air";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Air_Marker"]);
};

// Ordre d'engagement SAD (Search and Destroy) dirigé vers le secteur de combat
private _wp = _enemyAirGroup addWaypoint [_centerPos, 500];
_wp setWaypointType "SAD";
_wp setWaypointSpeed "FULL";
_wp setWaypointBehaviour "COMBAT";

// =============================================================================
// 5. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
while { ({ alive _x } count _targetPlanes) > 0 } do {
    private _livingPlanes = _targetPlanes select { alive _x };

    if (_livingPlanes isNotEqualTo []) then {
        // Si l'avion suivi est abattu, basculer immédiatement sur le prochain avion vivant
        if (isNull _currentTracked || {!alive _currentTracked}) then {
            _currentTracked = _livingPlanes select 0;
            [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
        };

        // Mise à jour de la position du marqueur sur la cible vivante
        if (!isNull _currentTracked && {alive _currentTracked}) then {
            _mrkName setMarkerPosLocal (getPos _currentTracked);
        };
    };

    sleep 0.5;
};

// Suppression propre du marqueur tactique de suivi
deleteMarkerLocal _mrkName;

// Validation de la tâche
[_taskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
missionNamespace setVariable ["ORA_activeTaskTargets", [], true];

// Message radio BDA QG Overlord
["OVERLORD", localize "STR_ORA_Task_Air_Done", "STR_ORA_Task_Air_Done"] call ORA_fnc_radioMsg;

diag_log format ["[ORA-TASK] [AIR] [SUCCÈS] Tâche %1 accomplie : tous les bandits abattus.", _taskID];

// Nettoyage après crash
[_targetPlanes, _enemyAirGroup] spawn {
    params ["_jets", "_grp"];
    sleep 60;
    { deleteVehicle _x; } forEach _jets;
    { deleteVehicle _x; } forEach (units _grp);
};

true

