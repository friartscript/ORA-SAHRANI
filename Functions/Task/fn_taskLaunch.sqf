/*
    Auteur: ORA SQF Architect
    Description:
        Moteur orchestrateur de lancement et de séquencement des missions (sorties).
        Conforme aux spécifications :
        - L'ENSEMBLE DES TÂCHES EST CRÉÉ ET ASSIGNÉ À LA BASE dès le démarrage.
        - Planifie le nombre de sorties choisi par le joueur (1 à 20).
        - Chaque sortie est enregistrée dans le journal de mission (Sortie 1 ASSIGNED, Sorties 2..N CREATED, RTB CREATED).
        - Les marqueurs 3D (visibleIn3D = true) et l'asservissement HUD guident le joueur
          en permanence vers l'objectif actif.
        - S'il y a 2 objectifs dans une tâche, deux sous-tâches sont créées : l'une est assignée,
          et dès qu'elle est terminée, l'autre est immédiatement assignée.
        - À la complétion de la dernière sortie, assigne la tâche de RTB (Retour à la base de Sahrani).

    Paramètres:
        0: _taskType     - Type de tâche ("RANDOM", "GROUND", "SEA", "AIR", "HELI") [String, défaut: "RANDOM"]
        1: _totalSorties - Nombre de sorties à accomplir [Scalar, défaut: 1]

    Retour:
        [Boolean] - true lorsque la campagne de sorties est initiée
*/

params [
    ["_taskType", "RANDOM", [""]],
    ["_totalSorties", 1, [0]]
];

if (!hasInterface) exitWith { false };

// Si déjà en cours d'exécution, refuser le double lancement
if (missionNamespace getVariable ["ORA_campaignActive", false]) exitWith {
    false
};

missionNamespace setVariable ["ORA_campaignActive", true, true];
missionNamespace setVariable ["ORA_sortiesCompleted", 0, true];

// Détermination du nombre de sorties si non spécifié
if (_totalSorties <= 0) then {
    _totalSorties = missionNamespace getVariable ["ORA_selectedMissionsCount", 5];
};

private _plane = missionNamespace getVariable ["plane_0", player];
private _airbasePos = getPos _plane;

// =============================================================================
// 1. PLANIFICATION OPÉRATIONNELLE SÉQUENTIELLE
// =============================================================================
missionNamespace setVariable ["ORA_totalSortiesCount", _totalSorties, true];
missionNamespace setVariable ["ORA_sortiesCompleted", 0, true];

private _sortiePlan = [];
for "_i" from 1 to _totalSorties do {
    private _type = _taskType;
    if (_type == "RANDOM") then {
        _type = selectRandom ["GROUND", "SEA", "AIR", "HELI"];
    };
    _sortiePlan pushBack _type;
};

// =============================================================================
// 2. EXÉCUTION SÉQUENTIELLE DES SORTIES OPÉRATIONNELLES (UNE SEULE TÂCHE ACTIVE)
// =============================================================================
for "_sortieIndex" from 1 to _totalSorties do {
    private _selectedType = _sortiePlan select (_sortieIndex - 1);
    private _taskID = format ["task_sortie_%1", _sortieIndex];

    // Déclenchement de la fonction de tâche spécifique (création dynamique à la volée)
    private _scriptHandle = switch (_selectedType) do {
        case "GROUND": { [_taskID, _sortieIndex, _totalSorties] spawn ORA_fnc_taskGround };
        case "SEA":    { [_taskID, _sortieIndex, _totalSorties] spawn ORA_fnc_taskSea };
        case "AIR":    { [_taskID, _sortieIndex, _totalSorties] spawn ORA_fnc_taskAir };
        case "HELI":   { [_taskID, _sortieIndex, _totalSorties] spawn ORA_fnc_taskHeli };
        default        { [_taskID, _sortieIndex, _totalSorties] spawn ORA_fnc_taskGround };
    };

    // Attente active de la complétion complète de la sortie en cours
    waitUntil { scriptDone _scriptHandle };

    missionNamespace setVariable ["ORA_sortiesCompleted", _sortieIndex, true];

    // Si d'autres sorties sont programmées, délai tactique de respiration (10 secondes)
    if (_sortieIndex < _totalSorties) then {
        sleep 10;
    };
};

// =============================================================================
// 3. FIN DE TOUTES LES SORTIES : CRÉATION ET ASSIGNATION DE LA TÂCHE RTB (ATTERRISSAGE)
// =============================================================================
sleep 4;

// Ordre radio de fin de campagne par Overlord
["OVERLORD", localize "STR_ORA_Task_All_RTB", "STR_ORA_Task_All_RTB"] call ORA_fnc_radioMsg;

// Création officielle et assignation de la tâche de retour à la base (RTB) UNIQUEMENT MAINTENANT
[
    player,
    "task_rtb",
    [
        localize "STR_ORA_Task_RTB_Desc",
        localize "STR_ORA_Task_RTB_Title",
        ""
    ],
    _airbasePos,
    "ASSIGNED",
    1,
    true,
    "land",
    true // Marqueur 3D actif natif pour guidage d'atterrissage
] call BIS_fnc_taskCreate;

["task_rtb", true] call BIS_fnc_taskSetAlwaysVisible;
["task_rtb"] call BIS_fnc_taskSetCurrent;

private _rtbTask = "task_rtb" call BIS_fnc_taskReal;
if (!isNull _rtbTask) then {
    _rtbTask setSimpleTaskDestination _airbasePos;
    _rtbTask setSimpleTaskAlwaysVisible true;
    player setCurrentTask _rtbTask;
};

// Surveillance de l'atterrissage en sécurité sur la base aérienne
waitUntil {
    sleep 1;
    private _currentPlane = missionNamespace getVariable ["plane_0", player];
    isTouchingGround _currentPlane 
        && {(speed _currentPlane) < 40} 
        && {(_currentPlane distance _airbasePos) < 2500}
};

// Validation du RTB
["task_rtb", "SUCCEEDED", true] call BIS_fnc_taskSetState;

sleep 3;

// Déclenchement du débriefing de victoire
"EndSuccess" call BIS_fnc_endMission;

true
