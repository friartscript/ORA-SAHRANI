/*
    Auteur: ORA SQF Architect
    Description:
        Initialise la logique serveur et l'état global de la mission.
    Paramètres:
        Aucun
    Retour:
        [Boolean] - true si initialisé avec succès
    Exemple:
        [] call ORA_fnc_initMission;
*/
if (!isServer) exitWith { false };

diag_log "[ORA-CORE] [INIT] Initialisation du serveur de mission...";

// Initialisation des variables globales de suivi d'opération
missionNamespace setVariable ["ORA_missionStarted", true, true];
missionNamespace setVariable ["ORA_currentAlertLevel", 1, true];

// Configuration de la météo ou de l'environnement si nécessaire
0 setOvercast 0.2;
0 setFog [0.02, 0.05, 50];
0 setRain 0;

// Initialisation des compétences tactiques des IA
[] call ORA_fnc_initSkills;

diag_log "[ORA-CORE] [OK] Initialisation du serveur terminée.";

true

