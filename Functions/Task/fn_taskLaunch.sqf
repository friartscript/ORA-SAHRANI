/*
    Auteur: ORA SQF Architect
    Description:
        Moteur orchestrateur de lancement et de séquencement des missions (sorties).
        Conforme aux spécifications :
        - Lance une tâche unique ou une série de sorties (1 à 20) selon le choix du joueur.
        - Supporte les types de tâches : "RANDOM", "GROUND", "SEA", "AIR", "HELI".
        - Enchaîne les missions avec délai opérationnel et transmissions radio QG.
        - À la complétion de la dernière sortie, génère l'ordre et la tâche de RTB
          (Retour à la base aérienne de Sahrani) avec débriefing de victoire lors de l'atterrissage.

    Paramètres:
        0: _taskType     - Type de tâche ("RANDOM", "GROUND", "SEA", "AIR", "HELI") [String, défaut: "RANDOM"]
        1: _totalSorties - Nombre de sorties à accomplir [Scalar, défaut: 1]

    Retour:
        [Boolean] - true lorsque la campagne de sorties est initiée

    Exemples:
        // Lancer une mission aléatoire unique :
        ["RANDOM", 1] spawn ORA_fnc_taskLaunch;

        // Lancer une campagne de 5 sorties consécutives :
        ["RANDOM", 5] spawn ORA_fnc_taskLaunch;

        // Lancer spécifiquement une frappe maritime :
        ["SEA", 1] spawn ORA_fnc_taskLaunch;
*/

params [
    ["_taskType", "RANDOM", [""]],
    ["_totalSorties", 1, [0]]
];

if (!hasInterface) exitWith { false };

// Si déjà en cours d'exécution, refuser le double lancement
if (missionNamespace getVariable ["ORA_campaignActive", false]) exitWith {
    diag_log "[ORA-TASK] [INFO] Une campagne opérationnelle est déjà active.";
    false
};

missionNamespace setVariable ["ORA_campaignActive", true, true];
missionNamespace setVariable ["ORA_sortiesCompleted", 0, true];

// Détermination du nombre de sorties si non spécifié
if (_totalSorties <= 0) then {
    _totalSorties = missionNamespace getVariable ["ORA_selectedMissionsCount", 5];
};

diag_log format ["[ORA-TASK] [LAUNCHER] Lancement de la campagne : %1 sorties (Type: %2)...", _totalSorties, _taskType];

private _plane = missionNamespace getVariable ["plane_0", player];
private _airbasePos = getPos _plane;

// =============================================================================
// BOUCLE SÉQUENTIELLE DES SORTIES OPÉRATIONNELLES
// =============================================================================
for "_sortieIndex" from 1 to _totalSorties do {
    // 1. Détermination du type de tâche pour cette sortie
    private _selectedType = _taskType;
    if (_selectedType == "RANDOM") then {
        _selectedType = selectRandom ["GROUND", "SEA", "AIR", "HELI"];
    };

    private _taskID = format ["task_%1_%2", toLower _selectedType, _sortieIndex];

    diag_log format ["[ORA-TASK] [LAUNCHER] Lancement Sortie %1/%2 : %3 (ID: %4)", _sortieIndex, _totalSorties, _selectedType, _taskID];

    // 2. Déclenchement de la fonction de tâche spécifique
    private _scriptHandle = switch (_selectedType) do {
        case "GROUND": { [_taskID, _sortieIndex] spawn ORA_fnc_taskGround };
        case "SEA":    { [_taskID, _sortieIndex] spawn ORA_fnc_taskSea };
        case "AIR":    { [_taskID, _sortieIndex] spawn ORA_fnc_taskAir };
        case "HELI":   { [_taskID, _sortieIndex] spawn ORA_fnc_taskHeli };
        default        { [_taskID, _sortieIndex] spawn ORA_fnc_taskGround };
    };

    // 3. Attente active de la complétion de la sortie en cours
    waitUntil { scriptDone _scriptHandle };

    missionNamespace setVariable ["ORA_sortiesCompleted", _sortieIndex, true];

    diag_log format ["[ORA-TASK] [LAUNCHER] Sortie %1/%2 accomplie avec succès.", _sortieIndex, _totalSorties];

    // 4. Si d'autres sorties sont programmées, délai tactique de respiration (12 secondes)
    if (_sortieIndex < _totalSorties) then {
        sleep 12;
    };
};

// =============================================================================
// FIN DES SORTIES : ORDRE ET TÂCHE DE RETOUR À LA BASE (RTB)
// =============================================================================
sleep 5;

// Ordre radio de fin de campagne par Overlord
["OVERLORD", localize "STR_ORA_Task_All_RTB", "STR_ORA_Task_All_RTB"] call ORA_fnc_radioMsg;

// Création de la tâche de retour à la base (RTB)
[
    true,
    "task_rtb",
    [
        localize "STR_ORA_Task_RTB_Desc",
        localize "STR_ORA_Task_RTB_Title",
        localize "STR_ORA_Task_RTB_Marker"
    ],
    _airbasePos,
    "AUTOASSIGNED",
    10,
    true,
    "takeoff",
    false
] call BIS_fnc_taskCreate;

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

