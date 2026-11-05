/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de frappe contre une force héliportée d'assaut.
        Conforme aux spécifications :
        - Distance minimale garantie : STRICTEMENT supérieure à 2000m du joueur (2500m - 7000m).
        - Fait apparaître 1 à 3 hélicoptères de combat/manœuvre volant en basse altitude (30-80m).
        - Fait apparaître 5 à 15 unités d'infanterie ennemie au sol.
        - Fait apparaître une escouade alliée RACS (4 à 8 soldats avec dotation INFO_EDITOR.md).
        - MOUVEMENT DYNAMIQUE : Les troupes au sol se déplacent et convergent vers le secteur
          de contact pendant que les hélicoptères patrouillent à basse altitude.
        - Signalement visuel : fumigène vert allié pour identification.
        - RÈGLE CONTRACTUELLE : La réussite se limite STRICTEMENT à l'élimination des hélicoptères.
          L'infanterie au sol participe à l'engagement mais sa destruction n'est pas requise.
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

diag_log format ["[ORA-TASK] [HELI] Démarrage de la tâche %1 (Sortie %2)...", _taskID, _orderNum];

private _plane = missionNamespace getVariable ["plane_0", player];
private _playerPos = getPos _plane;

// =============================================================================
// 1. DÉFINITION DU POINT DE COMBAT (STRICTEMENT >= 2500m)
// =============================================================================
private _clashPos = [];
private _attempts = 0;

while {_attempts < 40 && {_clashPos isEqualTo []}} do {
    _attempts = _attempts + 1;
    private _dir = random 360;
    private _dist = 2500 + (random 4500);
    private _testPos = _playerPos getPos [_dist, _dir];

    if (!surfaceIsWater _testPos) then {
        private _flatPos = _testPos isFlatEmpty [10, 0, 0.4, 25, 0, false, objNull];
        if !(_flatPos isEqualTo []) then {
            _clashPos = _flatPos;
        };
    };
};

if (_clashPos isEqualTo [] || {(_clashPos distance _playerPos) < 2000}) then {
    private _safeDir = random 360;
    _clashPos = _playerPos getPos [3300, _safeDir];
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
        localize "STR_ORA_Task_Heli_Desc",
        format ["[%1] %2", _orderNum, localize "STR_ORA_Task_Heli_Title"],
        localize "STR_ORA_Task_Heli_Marker"
    ],
    _clashPos,
    "AUTOASSIGNED",
    5,
    true,
    "destroy",
    false
] call BIS_fnc_taskCreate;

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
// 4. CIBLES PRIORITAIRES : 1 À 3 HÉLICOPTÈRES EN VOL BASSE ALTITUDE (30-80M)
// =============================================================================
private _numHelis = 1 + floor (random 3);
private _targetHelis = [];
private _enemyHeliGroup = createGroup [east, true];

for "_i" from 1 to _numHelis do {
    private _hClass = selectRandom _heliClasses;
    private _hPos = _clashPos getPos [50 * _i, _approachDir + 180];
    private _alt = 35 + (random 45);
    _hPos set [2, _alt];

    private _heli = createVehicle [_hClass, _hPos, [], 0, "FLY"];
    _heli setDir _approachDir;
    _heli flyInHeight _alt;
    _heli setVelocityModelSpace [0, 30, 0];

    _heli allowDamage false;
    [_heli] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _heli;
    (crew _heli) joinSilent _enemyHeliGroup;

    _heli setVariable ["ORA_isEnemy", true, true];
    _targetHelis pushBack _heli;
    sleep 0.2;
};

// Enregistrement des cibles de la tâche pour le guidage d'armement
missionNamespace setVariable ["ORA_activeTaskTargets", _targetHelis, true];

// Rattachement immédiat de la tâche et création du marqueur dynamique de suivi
private _mrkName = format ["mrk_tactical_%1", _taskID];
private _currentTracked = if (_targetHelis isNotEqualTo []) then { _targetHelis select 0 } else { objNull };

if (!isNull _currentTracked) then {
    [_taskID, _currentTracked] call BIS_fnc_taskSetDestination;
    createMarkerLocal [_mrkName, getPos _currentTracked];
    _mrkName setMarkerTypeLocal "o_air";
    _mrkName setMarkerColorLocal "ColorRed";
    _mrkName setMarkerTextLocal (format [" %1", localize "STR_ORA_Task_Heli_Marker"]);
};

// Patrouille basse altitude au-dessus du secteur
for "_w" from 1 to 4 do {
    private _wpPos = _clashPos getPos [250 + (_w * 100), _w * 90];
    private _wp = _enemyHeliGroup addWaypoint [_wpPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "NORMAL";
    _wp setWaypointBehaviour "COMBAT";
    if (_w == 4) then {
        _wp setWaypointType "CYCLE";
    };
};

// =============================================================================
// 5. INFANTERIE ENNEMIE AU SOL (5 À 15 UNITÉS EN MOUVEMENT)
// =============================================================================
private _numEnemyInf = 5 + floor (random 11);
private _enemyInfGroup = createGroup [east, true];
private _enemyInfSpawn = _clashPos getPos [300 + random 80, _approachDir + 180];
_enemyInfSpawn set [2, 0.2];

for "_i" from 1 to _numEnemyInf do {
    private _infClass = selectRandom _infantryClasses;
    private _pPos = _enemyInfSpawn getPos [4 + random 25, random 360];
    _pPos set [2, 0.2];

    private _unit = _enemyInfGroup createUnit [_infClass, _pPos, [], 0, "CAN_COLLIDE"];
    _unit setPosATL _pPos;

    _unit allowDamage false;
    [_unit] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    sleep 0.05;
};

private _wpEnemyInf = _enemyInfGroup addWaypoint [_clashPos, 20];
_wpEnemyInf setWaypointType "MOVE";
_wpEnemyInf setWaypointSpeed "NORMAL";
_wpEnemyInf setWaypointBehaviour "AWARE";

// =============================================================================
// 6. ESCOUADE ALLIÉE RACS (4 À 8 SOLDATS EN MOUVEMENT DE RENFORT)
// =============================================================================
private _alliedSpawnPos = _clashPos getPos [280 + random 80, _approachDir];
_alliedSpawnPos set [2, 0.2];

private _numAllies = 4 + floor (random 5);
private _alliedGroup = createGroup [independent, true];

for "_i" from 1 to _numAllies do {
    private _aClass = selectRandom _infantryClasses;
    private _aPos = _alliedSpawnPos getPos [4 + random 20, random 360];
    _aPos set [2, 0.2];

    private _ally = _alliedGroup createUnit [_aClass, _aPos, [], 0, "CAN_COLLIDE"];
    _ally setPosATL _aPos;

    _ally allowDamage false;
    [_ally] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    [_ally] call ORA_fnc_applyRACSLoadout;

    sleep 0.05;
};

// Déplacement allié vers le point de contact
private _wpAlly1 = _alliedGroup addWaypoint [_clashPos, 0];
_wpAlly1 setWaypointType "MOVE";
_wpAlly1 setWaypointSpeed "NORMAL";
_wpAlly1 setWaypointBehaviour "AWARE";

private _wpAlly2 = _alliedGroup addWaypoint [_clashPos, 40];
_wpAlly2 setWaypointType "GUARD";

// Fumigène vert allié pour marquer la position au jet
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
while { ({ alive _x } count _targetHelis) > 0 } do {
    private _livingHelis = _targetHelis select { alive _x };

    if (_livingHelis isNotEqualTo []) then {
        // Si l'hélicoptère suivi est abattu, basculer immédiatement sur le prochain appareil vivant
        if (isNull _currentTracked || {!alive _currentTracked}) then {
            _currentTracked = _livingHelis select 0;
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
["OVERLORD", localize "STR_ORA_Task_Heli_Done", "STR_ORA_Task_Heli_Done"] call ORA_fnc_radioMsg;

diag_log format ["[ORA-TASK] [HELI] [SUCCÈS] Tâche %1 accomplie : tous les hélicoptères abattus.", _taskID];

// Nettoyage après crash et éloignement
[_targetHelis, _enemyInfGroup, _alliedGroup] spawn {
    params ["_helis", "_enemyGrp", "_allyGrp"];
    sleep 60;
    waitUntil {
        sleep 5;
        (player distance (_helis select 0)) > 2500
    };
    { deleteVehicle _x; } forEach _helis;
    { deleteVehicle _x; } forEach (units _enemyGrp);
    { deleteVehicle _x; } forEach (units _allyGrp);
};

true
