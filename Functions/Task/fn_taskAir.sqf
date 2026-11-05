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

// =============================================================================
// 2. RATTACHEMENT OU CRÉATION DE LA TÂCHE OFFICIELLE
// =============================================================================
if (!([_taskID] call BIS_fnc_taskExists)) then {
    [
        true,
        _taskID,
        [
            localize "STR_ORA_Task_Air_Desc",
            format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Air_Title"],
            localize "STR_ORA_Task_Air_Marker"
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

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetPlanes isNotEqualTo []) then { _targetPlanes select 0 } else { objNull };

if (!isNull _currentTracked) then {
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_air";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Air_Marker"]);
};

// Gestion multi-objectifs : si 2 objectifs ou plus, créer des sous-tâches dédiées
private _objTaskData = [];
if ((count _targetPlanes) >= 2) then {
    for "_k" from 0 to ((count _targetPlanes) - 1) do {
        private _tJet = _targetPlanes select _k;
        private _objID = format ["%1_obj_%2", _taskID, _k + 1];
        private _objTitle = format ["%1 %2 : %3", localize "STR_ORA_Task_Objective", _k + 1, localize "STR_ORA_Task_Air_Marker"];
        private _objDesc = format ["%1 (%2 %3)", localize "STR_ORA_Task_Air_Desc", localize "STR_ORA_Task_Objective", _k + 1];
        private _objState = if (_k == 0) then { "ASSIGNED" } else { "CREATED" };

        [
            true,
            [_objID, _taskID],
            [_objDesc, _objTitle, ""],
            _tJet,
            _objState,
            5,
            (_k == 0),
            "destroy",
            false
        ] call BIS_fnc_taskCreate;

        _objTaskData pushBack [_tJet, _objID, false];
    };
    [format ["%1_obj_1", _taskID]] call BIS_fnc_taskSetCurrent;
} else {
    if (!isNull _currentTracked) then {
        [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    };
};

// Ordre d'engagement SAD (Search and Destroy) dirigé vers le secteur opérationnel
private _wp = _enemyAirGroup addWaypoint [_centerPos, 500];
_wp setWaypointType "SAD";
_wp setWaypointSpeed "FULL";
_wp setWaypointBehaviour "COMBAT";
_wp setWaypointCombatMode "RED";

// =============================================================================
// 5. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
if (_objTaskData isNotEqualTo []) then {
    private _activeIdx = 0;
    private _activeObjTask = _objTaskData select 0 select 1;

    while { ({ alive (_x select 0) } count _objTaskData) > 0 } do {
        {
            _x params ["_tJet", "_tID", "_done"];
            if (!_done && {!alive _tJet}) then {
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
    while { ({ alive _x } count _targetPlanes) > 0 } do {
        private _livingPlanes = _targetPlanes select { alive _x };
        if (_livingPlanes isNotEqualTo []) then {
            if (isNull _currentTracked || {!alive _currentTracked}) then {
                _currentTracked = _livingPlanes select 0;
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
["OVERLORD", localize "STR_ORA_Task_Air_Done", "STR_ORA_Task_Air_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche :
// Toutes les unités aériennes et épaves disparaissent immédiatement si à plus de 2000m du joueur,
// ou dès que le joueur s'éloigne à plus de 2000m.
[_createdEntities, [_enemyAirGroup], 2000] spawn ORA_fnc_taskCleanup;

true
