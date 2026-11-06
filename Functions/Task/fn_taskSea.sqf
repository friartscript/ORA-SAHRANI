/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe navale (Anti-Navires / Mer).
        Conforme aux spécifications :
        - Les missions en mer s'effectuent STRICTEMENT sur les marqueurs :
          marker_blue_0 à marker_blue_39 (ordre croissant cohérent de déplacement).
        - Ces balises forment un circuit maritime complet évitant tout échouement.
        - Fait apparaître 1 à 4 bâtiments/navires de guerre ennemis.
        - Les navires respectent rigoureusement le sens séquentiel (0 -> 1 -> 2 ... -> 39 -> 0).
        - RÈGLE CONTRACTUELLE : Aucune infanterie au sol.
        - Se limite strictement à la destruction de la flottille ennemie.
        - Asservissement complet des marqueurs 3D et HUD guidant le joueur directement
          vers les navires en mer (visibleIn3D = true + Draw3D).
        - Ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_sea_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès
*/

params [
    ["_taskID", format ["task_sea_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]],
    ["_totalOrders", 0, [0]]
];

if (_totalOrders <= 0) then {
    _totalOrders = missionNamespace getVariable ["ORA_totalSortiesCount", missionNamespace getVariable ["ORA_selectedMissionsCount", 1]];
};

if (!hasInterface) exitWith { false };

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. RECHERCHE DE BALISES MARITIMES VALIDES (marker_blue_0 à marker_blue_39)
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

// Sélection aléatoire d'une balise maritime de départ
private _selectedPair = selectRandom _seaMarkers;
private _startIdx = _selectedPair select 0;
private _spawnMrk = _selectedPair select 1;

private _targetPos = getMarkerPos _spawnMrk;
_targetPos set [2, 0];

private _gridStr = mapGridPosition _targetPos;

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

// L'ordre des balises est STRICTEMENT séquentiel croissant (0 -> 1 -> 2 ... -> 39 -> 0)
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
// 6. GESTION SÉQUENTIELLE STRICTE : UNE TÂCHE APRÈS L'AUTRE (JAMAIS ENSEMBLE)
// =============================================================================
for "_k" from 0 to ((count _targetBoats) - 1) do {
    private _target = _targetBoats select _k;
    private _subTaskID = if ((count _targetBoats) > 1) then {
        format ["%1_obj_%2", _taskID, _k + 1]
    } else {
        _taskID
    };

    private _taskTitle = if ((count _targetBoats) > 1) then {
        format ["[%1/%2] %3 (%4/%5)", _orderNum, _totalOrders, localize "STR_ORA_Task_Sea_Title", _k + 1, count _targetBoats]
    } else {
        format ["[%1/%2] %3", _orderNum, _totalOrders, localize "STR_ORA_Task_Sea_Title"]
    };

    // Révélation impérative au joueur et activation des waypoints 3D HUD natifs
    player reveal [_target, 4];
    (group player) reveal [_target, 4];
    showWaypoints true;

    // Création et assignation de CETTE TÂCHE SEULEMENT (la suivante n'existe pas encore !)
    [
        player,
        _subTaskID,
        [localize "STR_ORA_Task_Sea_Desc", _taskTitle, ""],
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

    if (_k < ((count _targetBoats) - 1)) then {
        playSoundUI ["ORA_Warning_Beep", 0.6, 1.2, false];
        sleep 1.0;
    };
};

// Message radio BDA QG Overlord
["OVERLORD", localize "STR_ORA_Task_Sea_Done", "STR_ORA_Task_Sea_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche
[_createdEntities, [_enemySeaGroup], 2000] spawn ORA_fnc_taskCleanup;

true
