/*
    Auteur: ORA SQF Architect
    Description: Point d'entrée d'initialisation locale pour le joueur client.
    Paramètres:
        0: _player - Objet joueur [Object]
        1: _didJIP - Indique si la connexion s'est faite en cours de partie [Boolean]
*/
params ["_player", "_didJIP"];

if (!hasInterface) exitWith {};

// Attente que l'environnement local du joueur soit stabilisé
waitUntil {!isNull player && {alive player}};

// Lancement de l'initialisation du joueur
[_player] spawn ORA_fnc_initLocal;

