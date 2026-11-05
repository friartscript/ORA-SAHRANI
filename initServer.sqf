/*
    Auteur: ORA SQF Architect
    Description: Point d'entrée d'initialisation côté serveur ou hôte solo.
*/
if (!isServer) exitWith {};

// Initialisation globale de la mission
[] call ORA_fnc_initMission;

