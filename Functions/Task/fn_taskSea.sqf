/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe navale en haute mer.
        Conforme aux spécifications :
        - Fait apparaître 1 à 4 bateaux/navires en mer (Zubr LCAC, Frégate, Speedboats armés).
        - Définit des mouvements de patrouille maritime dynamiques (waypoints en mer).
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

diag_log format ["[ORA-TASK] [SEA] Démarrage de la tâche %1 (Sortie %2)...", _taskID, _orderNum];

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. RECHERCHE D'UNE ZONE MARITIME EN EAU PROFONDE AUTOUR DE SAHRANI
// =============================================================================
private _centerPos = getPos _plane;
private _targetPos = [];
private _attempts = 0;

while {_attempts < 40 && {_targetPos isEqualTo []}} do {
    _attempts = _attempts + 1;
    private _dir = random 360;
    private _dist = 4000 + (random 6000);
    private _testPos = _centerPos getPos [_dist, _dir];

    // Vérifier que c'est de l'eau avec une profondeur suffisante (> 6m)
    if (surfaceIsWater _testPos && {getTerrainHeightASL _testPos < -6}) then {
        _targetPos = _testPos;
    };
};

if (_targetPos isEqualTo []) then {
    // Coordonnées maritimes au large de Sahrani Sud/Est
    _targetPos = [16000, 6000, 0];
};

private _gridStr = mapGridPosition _targetPos;

// =============================================================================
// 2. CRÉATION DE LA TÂCHE (BIS_fnc_taskCreate)
// =============================================================================
[
    true,
    _taskID,
    [
        localize "STR_ORA_Task_Sea_Desc",
        format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Sea_Title"],
        localize "STR_ORA_Task_Sea_Marker"
    ],
    _targetPos,
    "AUTOASSIGNED",
    5,
    true,
    "destroy",
    false
] call BIS_fnc_taskCreate;

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
// 4. APPARITION DES CIBLES : 1 À 4 BATEAUX EN MER AVEC MOUVEMENTS DYNAMIQUES
// =============================================================================
private _numBoats = 1 + floor (random 4);
private _targetBoats = [];
private _enemySeaGroup = createGroup [east, true];

for "_i" from 1 to _numBoats do {
    private _bClass = selectRandom _boatClasses;
    private _spawnPos = _targetPos getPos [50 * _i, random 360];
    _spawnPos set [2, 0];

    private _boat = createVehicle [_bClass, _spawnPos, [], 0, "NONE"];
    _boat setDir (random 360);

    _boat allowDamage false;
    [_boat] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _boat;
    (crew _boat) joinSilent _enemySeaGroup;

    _boat setVariable ["ORA_isEnemy", true, true];
    _targetBoats pushBack _boat;
    sleep 0.2;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetBoats, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetBoats isNotEqualTo []) then { _targetBoats select 0 } else { objNull };

if (!isNull _currentTracked) then {
    [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_naval";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Sea_Marker"]);
};

// Configuration des mouvements de patrouille en mer
for "_w" from 1 to 4 do {
    private _wpPos = _targetPos getPos [300 + (_w * 200), _w * 90];
    if (surfaceIsWater _wpPos) then {
        private _wp = _enemySeaGroup addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "NORMAL";
        _wp setWaypointBehaviour "AWARE";
        if (_w == 4) then {
            _wp setWaypointType "CYCLE";
        };
    };
};

// =============================================================================
// 5. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
while { ({ alive _x } count _targetBoats) > 0 } do {
    private _livingBoats = _targetBoats select { alive _x };

    if (_livingBoats isNotEqualTo []) then {
        // Si le navire suivi est coulé, basculer immédiatement sur le prochain bâtiment vivant
        if (isNull _currentTracked || {!alive _currentTracked}) then {
            _currentTracked = _livingBoats select 0;
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
["OVERLORD", localize "STR_ORA_Task_Sea_Done", "STR_ORA_Task_Sea_Done"] call ORA_fnc_radioMsg;

diag_log format ["[ORA-TASK] [SEA] [SUCCÈS] Tâche %1 accomplie : flottille ennemie coulée.", _taskID];

// Nettoyage après éloignement du joueur
[_targetBoats, _enemySeaGroup] spawn {
    params ["_boats", "_grp"];
    sleep 60;
    waitUntil {
        sleep 5;
        (player distance (_boats select 0)) > 3000
    };
    { deleteVehicle _x; } forEach _boats;
    { deleteVehicle _x; } forEach (units _grp);
};

true

