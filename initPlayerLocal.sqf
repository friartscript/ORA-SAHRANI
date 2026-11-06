/*
    Auteur: ORA SQF Architect
    Description: Point d'entrée d'initialisation locale pour le joueur client.
    Paramètres:
        0: _player - Objet joueur [Object]
        1: _didJIP - Indique si la connexion s'est faite en cours de partie [Boolean]
*/
params ["_player", "_didJIP"];

if (!hasInterface) exitWith {};

// ============================================================================
// DÉSACTIVATION DU CHAT AI ET ACTIVATION COMPLÈTE DU CANAL RADIO ET DES WAYPOINTS 3D
// ============================================================================
showChat false;
enableRadio true;
enableSentences false;
0 fadeRadio 1;
_player disableConversation true;

showWaypoints true;
showHUD [true, true, true, true, true, true, true, true, true];

// Verrouillage immédiat pour empêcher toute altération par des scripts d'équipement généralistes
_player setVariable ["ORA_isPilot", true, true];
player setVariable ["ORA_isPilot", true, true];

// Attente que l'environnement local du joueur soit stabilisé
waitUntil {!isNull player && {alive player}};

// Lancement de l'initialisation du joueur
[_player] spawn ORA_fnc_initLocal;
