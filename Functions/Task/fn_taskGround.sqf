/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe au sol (CAS / Anti-Blindés).
        Conforme aux spécifications :
        - Distance minimale garantie : STRICTEMENT supérieure à 2000m du joueur (2500m - 7000m).
        - Fait apparaître 1 à 3 véhicules terrestres ennemis (blindés, DCA, convois).
        - Fait apparaître 5 à 15 unités d'infanterie ennemie AAF.
        - Fait apparaître une escouade alliée RACS (4 à 8 soldats avec dotation INFO_EDITOR.md).
        - MOUVEMENT DYNAMIQUE : Les forces ennemies et les forces alliées convergent l'une vers
          l'autre vers un point de rendez-vous tactique et s'affrontent en combat d'infanterie.
        - Signalement visuel : fumigène vert allié (SmokeShellGreen) pour identification CAS.
        - RÈGLE CONTRACTUELLE : La réussite se limite STRICTEMENT à l'élimination des véhicules.
          L'infanterie au sol participe au combat mais sa destruction n'est pas requise.
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

diag_log format ["[ORA-TASK] [GROUND] Démarrage de la tâche %1 (Sortie %2)...", _taskID, _orderNum];

private _plane = missionNamespace getVariable ["plane_0", player];
private _playerPos = getPos _plane;

// =============================================================================
// 1. DÉFINITION DU POINT DE RENDEZ-VOUS / COMBAT (STRICTEMENT >= 2500m)
// =============================================================================
private _clashPos = [];
private _attempts = 0;

while {_attempts < 40 && {_clashPos isEqualTo []}} do {
    _attempts = _attempts + 1;
    private _dir = random 360;
    // Distance garantie entre 2500m et 7000m du joueur
    private _dist = 2500 + (random 4500);
    private _testPos = _playerPos getPos [_dist, _dir];

    if (!surfaceIsWater _testPos) then {
        private _flatPos = _testPos isFlatEmpty [8, 0, 0.4, 25, 0, false, objNull];
        if !(_flatPos isEqualTo []) then {
            _clashPos = _flatPos;
        };
    };
};

// Sécurité distance sur position de repli
if (_clashPos isEqualTo [] || {(_clashPos distance _playerPos) < 2000}) then {
    private _safeDir = random 360;
    _clashPos = _playerPos getPos [3200, _safeDir];
    _clashPos set [2, 0];
};

private _gridStr = mapGridPosition _clashPos;

// =============================================================================
// 2. CRÉATION DE LA TÂCHE (BIS_fnc_taskCreate)
// =============================================================================
[
    true,
    _taskID,
    [
        localize "STR_ORA_Task_Ground_Desc",
        format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Ground_Title"],
        localize "STR_ORA_Task_Ground_Marker"
    ],
    _clashPos,
    "AUTOASSIGNED",
    5,
    true,
    "destroy",
    false
] call BIS_fnc_taskCreate;

// Ordre radio Overlord via le système TTS
private _radioOrder = format [localize "STR_ORA_Task_Ground_Order", _gridStr];
["OVERLORD", _radioOrder, "STR_ORA_Task_Ground_Order"] call ORA_fnc_radioMsg;

// =============================================================================
// 3. CATALOGUES DES UNITÉS ET VÉHICULES (INFO_ENNEMIS.md)
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

// Axe d'approche pour le face-à-face tactique
private _approachDir = random 360;

// =============================================================================
// 4. FORCES ENNEMIES (AAF - Side EAST) EN MOUVEMENT
// =============================================================================
private _enemySpawnPos = _clashPos getPos [350 + random 100, _approachDir + 180];
_enemySpawnPos set [2, 0.2];

// A. 1 à 3 Véhicules blindés hostiles
private _numVehicles = 1 + floor (random 3);
private _targetVehicles = [];
private _enemyVehGroup = createGroup [east, true];

for "_i" from 1 to _numVehicles do {
    private _vClass = selectRandom _vehicleClasses;
    private _vPos = _enemySpawnPos getPos [20 * _i, _approachDir + 90];
    _vPos set [2, 0.2];

    private _veh = createVehicle [_vClass, _vPos, [], 0, "NONE"];
    _veh setDir _approachDir;

    _veh allowDamage false;
    [_veh] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _veh;
    (crew _veh) joinSilent _enemyVehGroup;

    _veh setVariable ["ORA_isEnemy", true, true];
    _targetVehicles pushBack _veh;
    sleep 0.15;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetVehicles, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetVehicles isNotEqualTo []) then { _targetVehicles select 0 } else { objNull };

if (!isNull _currentTracked) then {
    [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_armor";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Ground_Marker"]);
};

// B. 5 à 15 Fantassins ennemis
private _numEnemyInf = 5 + floor (random 11);
private _enemyInfGroup = createGroup [east, true];

for "_i" from 1 to _numEnemyInf do {
    private _iClass = selectRandom _infantryClasses;
    private _iPos = _enemySpawnPos getPos [5 + random 30, random 360];
    _iPos set [2, 0.2];

    private _unit = _enemyInfGroup createUnit [_iClass, _iPos, [], 0, "CAN_COLLIDE"];
    _unit setPosATL _iPos;

    _unit allowDamage false;
    [_unit] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    sleep 0.05;
};

// Ordre de mouvement ennemi vers le point de rendez-vous
private _wpEnemy1 = _enemyVehGroup addWaypoint [_clashPos, 0];
_wpEnemy1 setWaypointType "MOVE";
_wpEnemy1 setWaypointSpeed "NORMAL";
_wpEnemy1 setWaypointBehaviour "AWARE";

private _wpEnemy2 = _enemyVehGroup addWaypoint [_clashPos, 100];
_wpEnemy2 setWaypointType "SAD";

private _wpInf1 = _enemyInfGroup addWaypoint [_clashPos, 20];
_wpInf1 setWaypointType "MOVE";
_wpInf1 setWaypointSpeed "NORMAL";
_wpInf1 setWaypointBehaviour "AWARE";

private _wpInf2 = _enemyInfGroup addWaypoint [_clashPos, 100];
_wpInf2 setWaypointType "SAD";

// =============================================================================
// 5. FORCES ALLIÉES (RACS - Side INDEPENDENT) EN MOUVEMENT DE RENCONTRE
// =============================================================================
private _alliedSpawnPos = _clashPos getPos [300 + random 100, _approachDir];
_alliedSpawnPos set [2, 0.2];

private _numAllies = 4 + floor (random 5); // 4 à 8 soldats alliés RACS
private _alliedGroup = createGroup [independent, true];

for "_i" from 1 to _numAllies do {
    private _aClass = selectRandom _infantryClasses;
    private _aPos = _alliedSpawnPos getPos [4 + random 20, random 360];
    _aPos set [2, 0.2];

    private _ally = _alliedGroup createUnit [_aClass, _aPos, [], 0, "CAN_COLLIDE"];
    _ally setPosATL _aPos;

    _ally allowDamage false;
    [_ally] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    // Application contractuelle immédiate de la dotation RACS
    [_ally] call ORA_fnc_applyRACSLoadout;

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
};

// Ordre de déplacement allié vers le point de contact
private _wpAlly1 = _alliedGroup addWaypoint [_clashPos, 0];
_wpAlly1 setWaypointType "MOVE";
_wpAlly1 setWaypointSpeed "NORMAL";
_wpAlly1 setWaypointBehaviour "AWARE";

private _wpAlly2 = _alliedGroup addWaypoint [_clashPos, 60];
_wpAlly2 setWaypointType "GUARD";

// Déploiement automatique d'un fumigène vert allié à l'approche de la zone
[_alliedGroup, _clashPos] spawn {
    params ["_grp", "_target"];
    waitUntil {
        sleep 2;
        ({ alive _x } count (units _grp) == 0) || {((leader _grp) distance _target) < 150}
    };
    if ({ alive _x } count (units _grp) > 0) then {
        private _smokePos = getPosATL (leader _grp);
        createVehicle ["SmokeShellGreen", _smokePos, [], 0, "NONE"];
        diag_log "[ORA-TASK] [GROUND] Fumigène vert allié déclenché pour identification CAS.";
    };
};

// =============================================================================
// 6. SURVEILLANCE ET SUIVI EN TEMPS RÉEL (MARQUEUR ET DESTINATION DYNAMIQUES)
// =============================================================================
while { ({ alive _x } count _targetVehicles) > 0 } do {
    private _livingVehs = _targetVehicles select { alive _x };

    if (_livingVehs isNotEqualTo []) then {
        // Si le blindé suivi est détruit, basculer immédiatement sur le prochain véhicule vivant
        if (isNull _currentTracked || {!alive _currentTracked}) then {
            _currentTracked = _livingVehs select 0;
            [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
        };

        // Mise à jour continue de la position du marqueur sur la cible vivante
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
["OVERLORD", localize "STR_ORA_Task_Ground_Done", "STR_ORA_Task_Ground_Done"] call ORA_fnc_radioMsg;

diag_log format ["[ORA-TASK] [GROUND] [SUCCÈS] Tâche %1 accomplie : blindés ennemis détruits.", _taskID];

// Nettoyage après éloignement du joueur
[_targetVehicles, _enemyInfGroup, _alliedGroup] spawn {
    params ["_vehs", "_enemyGrp", "_allyGrp"];
    sleep 60;
    waitUntil {
        sleep 5;
        (player distance (_vehs select 0)) > 2500
    };
    { deleteVehicle _x; } forEach _vehs;
    { deleteVehicle _x; } forEach (units _enemyGrp);
    { deleteVehicle _x; } forEach (units _allyGrp);
};

true
