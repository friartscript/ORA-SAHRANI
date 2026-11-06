/*
    Auteur: ORA SQF Architect
    Description:
        Génère et supervise une mission de chasse anti-hélicoptère (CAS/Air-Sol).
        Conforme aux spécifications :
        - Les hélicoptères ennemis apparaissent STRICTEMENT sur les marqueurs oranges :
          marker_orange_0 à marker_orange_52 (secteurs de combat au sol).
        - Vol tactique basse altitude (40-80m) avec appui d'infanterie au sol.
        - Fait converger des troupes alliées RACS et ennemies AAF au sol.
        - RÈGLE CONTRACTUELLE : La réussite se limite STRICTEMENT à l'abattage des hélicoptères.
        - Asservissement complet des marqueurs 3D et HUD guidant le joueur directement
          vers les hélicos en vol (visibleIn3D = true + Draw3D).
        - Ordre radio QG (Overlord) avec coordonnées au format militaire et TTS.

    Paramètres:
        0: _taskID   - Identifiant unique de la tâche [String, défaut: "task_heli_1"]
        1: _orderNum - Index de sortie opérationnelle [Scalar, défaut: 1]

    Retour:
        [Boolean] - true si la tâche a été accomplie avec succès
*/

params [
    ["_taskID", format ["task_heli_%1", round (random 9999)], [""]],
    ["_orderNum", 1, [0]],
    ["_totalOrders", 0, [0]]
];

if (_totalOrders <= 0) then {
    _totalOrders = missionNamespace getVariable ["ORA_totalSortiesCount", missionNamespace getVariable ["ORA_selectedMissionsCount", 1]];
};

if (!hasInterface) exitWith { false };

private _plane = missionNamespace getVariable ["plane_0", player];

// =============================================================================
// 1. SÉLECTION D'UN SECTEUR DE COMBAT PARMI LES MARQUEURS ORANGES (marker_orange_0..52)
// =============================================================================
private _orangeMarkers = [];
for "_i" from 0 to 52 do {
    private _mrk = format ["marker_orange_%1", _i];
    if (getMarkerColor _mrk != "") then {
        _orangeMarkers pushBack _mrk;
    };
};

if (_orangeMarkers isEqualTo []) exitWith {
    false
};

private _spawnMrk = selectRandom _orangeMarkers;
private _clashPos = getMarkerPos _spawnMrk;
_clashPos set [2, 0];

private _gridStr = mapGridPosition _clashPos;

// =============================================================================
// 2. TRANSMISSION RADIO DU QG OVERLORD
// =============================================================================
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
// 4. CIBLES PRIORITAIRES : 1 À 3 HÉLICOPTÈRES EN VOL BASSE ALTITUDE (40-80M)
// =============================================================================
private _numHelis = 1 + floor (random 3);
private _targetHelis = [];
private _createdEntities = [];
private _enemyHeliGroup = createGroup [east, true];

for "_i" from 1 to _numHelis do {
    private _hClass = selectRandom _heliClasses;
    private _hPos = _clashPos getPos [80 * _i, _approachDir + (_i * 45)];
    private _hAlt = 45 + (random 35);
    _hPos set [2, _hAlt];

    private _heli = createVehicle [_hClass, _hPos, [], 0, "FLY"];
    _heli setPosASL _hPos;
    _heli setDir (random 360);
    _heli flyInHeight _hAlt;
    _heli setVelocityModelSpace [0, 45, 0];

    _heli allowDamage false;
    [_heli] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    createVehicleCrew _heli;
    (crew _heli) joinSilent _enemyHeliGroup;

    _heli setVariable ["ORA_isEnemy", true, true];
    _targetHelis pushBack _heli;
    _createdEntities pushBack _heli;
    _createdEntities append (crew _heli);
    sleep 0.15;
};

// Waypoints de patrouille et appui-feu pour les hélicoptères au-dessus du secteur
for "_w" from 1 to 4 do {
    private _wpHeliPos = _clashPos getPos [250 + (_w * 100), _w * 90];
    private _wpHeli = _enemyHeliGroup addWaypoint [_wpHeliPos, 0];
    _wpHeli setWaypointType "SAD";
    _wpHeli setWaypointSpeed "NORMAL";
    _wpHeli setWaypointBehaviour "COMBAT";
    _wpHeli setWaypointCombatMode "RED";
    if (_w == 4) then {
        _wpHeli setWaypointType "CYCLE";
    };
};

// =============================================================================
// 5. TROUPES ENNEMIES AU SOL AUTOUR DU MARQUEUR ORANGE
// =============================================================================
private _enemyGroundGroup = createGroup [east, true];
private _numEnemyInf = 5 + floor (random 6);

for "_i" from 1 to _numEnemyInf do {
    private _infClass = selectRandom _infantryClasses;
    private _infPos = _clashPos getPos [15 + (random 45), random 360];
    _infPos set [2, 0.1];

    private _infUnit = _enemyGroundGroup createUnit [_infClass, _infPos, [], 0, "CAN_COLLIDE"];
    _infUnit setPosATL _infPos;
    _infUnit allowDamage false;
    [_infUnit] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    _createdEntities pushBack _infUnit;
    sleep 0.05;
};

_enemyGroundGroup setCombatMode "RED";
_enemyGroundGroup setBehaviour "COMBAT";
private _wpGroundSAD = _enemyGroundGroup addWaypoint [_clashPos, 60];
_wpGroundSAD setWaypointType "SAD";

// =============================================================================
// 6. TROUPES ALLIÉES RACS AU SOL SOUS LE FEU
// =============================================================================
private _alliedGroup = createGroup [independent, true];
private _numAllies = 4 + floor (random 4);

for "_i" from 1 to _numAllies do {
    private _aClass = selectRandom _infantryClasses;
    private _aPos = _clashPos getPos [120 + (random 50), random 360];
    _aPos set [2, 0.1];

    private _ally = _alliedGroup createUnit [_aClass, _aPos, [], 0, "CAN_COLLIDE"];
    _ally setPosATL _aPos;
    _ally allowDamage false;
    [_ally] spawn { sleep 3; if (!isNull (_this select 0)) then { (_this select 0) allowDamage true; }; };

    [_ally] call ORA_fnc_applyRACSLoadout;

    _createdEntities pushBack _ally;
    sleep 0.05;
};

_alliedGroup setCombatMode "RED";
_alliedGroup setBehaviour "COMBAT";
private _wpAllyDefend = _alliedGroup addWaypoint [_clashPos, 40];
_wpAllyDefend setWaypointType "SAD";

// Fumigène vert allié de signalisation
[_alliedGroup] spawn {
    params ["_grp"];
    sleep 8;
    if ({ alive _x } count (units _grp) > 0) then {
        private _smokePos = getPosATL (leader _grp);
        createVehicle ["SmokeShellGreen", _smokePos, [], 0, "NONE"];
    };
};

// =============================================================================
// 7. GESTION DE LA TÂCHE UNIQUE DE SORTIE AVEC GUIDAGE 3D NATIF
// =============================================================================
private _taskTitle = format ["[%1/%2] %3", _orderNum, _totalOrders, localize "STR_ORA_Task_Heli_Title"];
private _currentTarget = _targetHelis select 0;

// Révélation impérative au joueur et activation des waypoints 3D HUD natifs
player reveal [_currentTarget, 4];
(group player) reveal [_currentTarget, 4];
showWaypoints true;

// Création d'une tâche unique par sortie, guidée par le marqueur 3D natif
[
    player,
    _taskID,
    [localize "STR_ORA_Task_Heli_Desc", _taskTitle, " "],
    _currentTarget,
    "ASSIGNED",
    5,
    true,
    "target",
    true
] call BIS_fnc_taskCreate;

[_taskID, true] call BIS_fnc_taskSetAlwaysVisible;
[_taskID] call BIS_fnc_taskSetCurrent;

private _realTask = _taskID call BIS_fnc_taskReal;
if (!isNull _realTask) then {
    _realTask setSimpleTaskTarget [_currentTarget, true];
    _realTask setSimpleTaskAlwaysVisible true;
    player setCurrentTask _realTask;
};

// Enregistrement de la cible active pour l'aide au tir
missionNamespace setVariable ["ORA_activeTaskTargets", [_currentTarget], true];

// Suivi et réassignation automatique de cible jusqu'à destruction de toutes les cibles
while { ({ alive _x && {!isNull _x} } count _targetHelis) > 0 } do {
    if (!alive _currentTarget || {isNull _currentTarget}) then {
        private _living = _targetHelis select { alive _x && {!isNull _x} };
        if (_living isNotEqualTo []) then {
            _currentTarget = _living select 0;
            [_taskID, _currentTarget] call BIS_fnc_taskSetDestination;
            private _rt = _taskID call BIS_fnc_taskReal;
            if (!isNull _rt) then {
                _rt setSimpleTaskTarget [_currentTarget, true];
                _rt setSimpleTaskAlwaysVisible true;
            };
            playSoundUI ["ORA_Warning_Beep", 0.6, 1.2, false];
        };
    };

    if (!isNull _currentTarget && {alive _currentTarget}) then {
        player reveal [_currentTarget, 4];
        (group player) reveal [_currentTarget, 4];
        missionNamespace setVariable ["ORA_activeTaskTargets", [_currentTarget], true];
    };

    sleep 0.5;
};

// Validation de la tâche de sortie
[_taskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
missionNamespace setVariable ["ORA_activeTaskTargets", [], true];

// Message radio BDA QG Overlord
["OVERLORD", localize "STR_ORA_Task_Heli_Done", "STR_ORA_Task_Heli_Done"] call ORA_fnc_radioMsg;

// Nettoyage automatique après fin de tâche
[_createdEntities, [_enemyHeliGroup, _enemyGroundGroup, _alliedGroup], 2000] spawn ORA_fnc_taskCleanup;

true
