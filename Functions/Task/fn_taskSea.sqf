/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe navale en haute mer.
        Conforme aux spécifications :
        - Les missions en mer s'effectuent STRICTEMENT le long du chapelet de balises
          maritimes : marker_blue_0 à marker_blue_39.
        - Ces marqueurs respectent un ordre cohérent de déplacement circulaire
          autour de Sahrani pour éviter que les bateaux ne s'échouent ou se coincent.
        - Fait apparaître 1 à 3 bateaux/navires de combat (LCAC, LCVP, Speedboats armés).
        - Les navires reçoivent des waypoints consécutifs suivant l'ordre des marqueurs.
        - RÈGLE CONTRACTUELLE : Aucune infanterie au sol.
        - Se limite strictement à la destruction des bateaux cibles.
        - Diffuse l'ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_sea_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès

    Exemple:
        ["task_sea_1", 1] spawn ORA_fnc_taskSea;
*/

params [
    ["_taskID", format ["task_sea_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]]
];

if (!hasInterface) exitWith { false };

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. SÉLECTION DU MARQUEUR DE DÉPART PARMI marker_blue_0 À marker_blue_39
// =============================================================================
private _seaMarkers = [];
for "_i" from 0 to 39 do {
    private _mrk = format ["marker_blue_%1", _i];
    if (getMarkerColor _mrk != "") then {
        _seaMarkers pushBack [_i, _mrk];
    };
};

if (_seaMarkers isEqualTo []) exitWith {
    false
};

// Choix aléatoire d'un point d'insertion maritime parmi les balises valides
private _selectedEntry = selectRandom _seaMarkers;
private _startIdx = _selectedEntry select 0;
private _startMrk = _selectedEntry select 1;
private _targetPos = getMarkerPos _startMrk;
_targetPos set [2, 0];

private _gridStr = mapGridPosition _targetPos;

// =============================================================================
// 2. RATTACHEMENT OU CRÉATION DE LA TÂCHE OFFICIELLE
// =============================================================================
if (!([_taskID] call BIS_fnc_taskExists)) then {
    [
        true,
        _taskID,
        [
            localize "STR_ORA_Task_Sea_Desc",
            format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Sea_Title"],
            localize "STR_ORA_Task_Sea_Marker"
        ],
        _targetPos,
        "ASSIGNED",
        5,
        true,
        "destroy",
        false
    ] call BIS_fnc_taskCreate;
} else {
    [_taskID, _targetPos] call BIS_fnc_taskSetDestination;
    [_taskID, "ASSIGNED", true] call BIS_fnc_taskSetState;
};

// Ordre radio Overlord via TTS
private _radioOrder = format [localize "STR_ORA_Task_Sea_Order", _gridStr];
["OVERLORD", _radioOrder, "STR_ORA_Task_Sea_Order"] call ORA_fnc_radioMsg;

// =============================================================================
// 3. CATALOGUE DES NAVIRES DE COMBAT (INFO_ENNEMIS.md)
// =============================================================================
private _boatClasses = [
    "I_Boat_Armed_01_minigun_F",
    "I_C_Boat_Transport_02_F"
];

if (isClass (configFile >> "CfgVehicles" >> "CUP_B_LCVP_VIV_USMC")) then {
    _boatClasses pushBack "CUP_B_LCVP_VIV_USMC";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_B_LCAC_USMC")) then {
    _boatClasses pushBack "CUP_B_LCAC_USMC";
};
if (isClass (configFile >> "CfgVehicles" >> "CUP_B_Frigate_ANZAC")) then {
    _boatClasses pushBack "CUP_B_Frigate_ANZAC";
};

// =============================================================================
// 4. APPARITION DE LA FLOTTILLE ENNEMIE SUR LA BALISE MARITIME
// =============================================================================
private _numBoats = 1 + floor (random 3);
private _targetBoats = [];
private _createdEntities = [];
private _enemySeaGroup = createGroup [east, true];

// L'ordre des balises est STRICTEMENT séquentiel croissant (0 -> 1 -> 2 -> ... -> 39 -> 0)
// Calcul du cap vers la balise suivante pour aligner les bateaux immédiatement dans le bon sens
private _nextIdx1 = (_startIdx + 1) mod 40;
private _firstWaypointPos = getMarkerPos (format ["marker_blue_%1", _nextIdx1]);
_firstWaypointPos set [2, 0];
private _initialHeading = _targetPos getDir _firstWaypointPos;

for "_i" from 1 to _numBoats do {
    private _bClass = selectRandom _boatClasses;
    // Espacement propre de 45 mètres en file indienne dans l'axe de navigation
    private _spawnPos = _targetPos getPos [45 * (_i - 1), _initialHeading + 180];
    _spawnPos set [2, 0];

    private _boat = createVehicle [_bClass, _spawnPos, [], 0, "NONE"];
    _boat setDir _initialHeading;
    _boat setPosASL [_spawnPos select 0, _spawnPos select 1, 0];

    _boat allowDamage false;
    [_boat] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _boat;
    (crew _boat) joinSilent _enemySeaGroup;

    _boat setVariable ["ORA_isEnemy", true, true];
    _targetBoats pushBack _boat;
    _createdEntities pushBack _boat;
    _createdEntities append (crew _boat);
    sleep 0.15;
};

// Configuration tactique du groupe naval : navigation en colonne le long du chenal
_enemySeaGroup setFormation "COLUMN";
_enemySeaGroup setSpeedMode "NORMAL";
_enemySeaGroup setBehaviour "AWARE";
_enemySeaGroup setCombatMode "RED";

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetBoats, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetBoats isNotEqualTo []) then { _targetBoats select 0 } else { objNull };

if (!isNull _currentTracked) then {
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_naval";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Sea_Marker"]);
};

// Gestion multi-objectifs : si 2 objectifs ou plus, créer des sous-tâches dédiées
private _objTaskData = [];
if ((count _targetBoats) >= 2) then {
    for "_k" from 0 to ((count _targetBoats) - 1) do {
        private _tBoat = _targetBoats select _k;
        private _objID = format ["%1_obj_%2", _taskID, _k + 1];
        private _objTitle = format ["%1 %2 : %3", localize "STR_ORA_Task_Objective", _k + 1, localize "STR_ORA_Task_Sea_Marker"];
        private _objDesc = format ["%1 (%2 %3)", localize "STR_ORA_Task_Sea_Desc", localize "STR_ORA_Task_Objective", _k + 1];
        private _objState = if (_k == 0) then { "ASSIGNED" } else { "CREATED" };

        [
            true,
            [_objID, _taskID],
            [_objDesc, _objTitle, ""],
            _tBoat,
            _objState,
            5,
            (_k == 0),
            "destroy",
            false
        ] call BIS_fnc_taskCreate;

        _objTaskData pushBack [_tBoat, _objID, false];
    };
    [format ["%1_obj_1", _taskID]] call BIS_fnc_taskSetCurrent;
} else {
    if (!isNull _currentTracked) then {
        [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    };
};

// =============================================================================
// 5. WAYPOINTS CONSECUTIFS SUIVANT STRICTEMENT L'ORDRE DES BALISES (0 À 39)
// =============================================================================
// Génération séquentielle le long des balises dans l'ordre croissant sans retour en arrière
for "_w" from 1 to 40 do {
    private _wpIdx = (_startIdx + _w) mod 40;
    private _wpMrk = format ["marker_blue_%1", _wpIdx];
    if (getMarkerColor _wpMrk != "") then {
        private _wpPos = getMarkerPos _wpMrk;
        _wpPos set [2, 0];

        private _wp = _enemySeaGroup addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "NORMAL";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointCompletionRadius 50;
    };
};

// Waypoint CYCLE de bouclage propre sur la première balise de navigation
private _loopMrk = format ["marker_blue_%1", (_startIdx + 1) mod 40];
if (getMarkerColor _loopMrk != "") then {
    private _loopPos = getMarkerPos _loopMrk;
    _loopPos set [2, 0];
    private _wpCycle = _enemySeaGroup addWaypoint [_loopPos, 0];
    _wpCycle setWaypointType "CYCLE";
};

// =============================================================================
// 6. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
if (_objTaskData isNotEqualTo []) then {
    private _activeIdx = 0;
    private _activeObjTask = _objTaskData select 0 select 1;

    while { ({ alive (_x select 0) } count _objTaskData) > 0 } do {
        {
            _x params ["_tBoat", "_tID", "_done"];
            if (!_done && {!alive _tBoat}) then {
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
    while { ({ alive _x } count _targetBoats) > 0 } do {
        private _livingBoats = _targetBoats select { alive _x };
        if (_livingBoats isNotEqualTo []) then {
            if (isNull _currentTracked || {!alive _currentTracked}) then {
                _currentTracked = _livingBoats select 0;
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
["OVERLORD", localize "STR_ORA_Task_Sea_Done", "STR_ORA_Task_Sea_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche :
// Toutes les unités maritimes et épaves disparaissent immédiatement si à plus de 2000m du joueur,
// ou dès que le joueur s'éloigne à plus de 2000m.
[_createdEntities, [_enemySeaGroup], 2000] spawn ORA_fnc_taskCleanup;

true
