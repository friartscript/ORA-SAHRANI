/*
    Auteur: ORA SQF Architect
    Description:
        Initialise le joueur local (player_0), lie le vecteur aérien (plane_0),
        active les modules d'immersion, configure le briefing et affiche le menu
        tactique au lancement conformément aux directives de PROMPT.md.
    Paramètres:
        0: _unit - L'entité joueur local [Object]
    Retour:
        [Boolean] - true si l'initialisation a réussi
    Exemple:
        [player] spawn ORA_fnc_initLocal;
*/
params [
    ["_unit", player, [objNull]]
];

if (!hasInterface) exitWith { false };

// Écran noir initial le temps d'ouvrir le menu
titleCut ["", "BLACK FADED", 999];

// Marquage prioritaire de l'unité joueur comme pilote de chasse officiel
_unit setVariable ["ORA_isPilot", true, true];

// Vérification de conformité avec l'éditeur (INFO_EDITOR.md)
private _expectedPlayer = missionNamespace getVariable ["player_0", objNull];
if (!isNull _expectedPlayer && {!(_unit isEqualTo _expectedPlayer)}) then {
    diag_log format ["[ORA] [INFO] L'unité locale (%1) diffère de la référence player_0 (%2). Poursuite de la dotation sur le joueur.", _unit, _expectedPlayer];
};

// Configuration de l'identité et dotation officielle de pilote de chasse
[_unit] call ORA_fnc_initIdentity;
[_unit] call ORA_fnc_initLoadout;

// Initialisation du briefing officiel et manuel de vol
[] call ORA_fnc_setupBriefing;
[] call ORA_fnc_initBriefing;
[] call ORA_fnc_initContext;

// Récupération de l'appareil assigné (INFO_EDITOR.md)
private _plane = missionNamespace getVariable ["plane_0", objNull];
if (isNull _plane) then {
    diag_log "[ORA] [INFO] plane_0 n'est pas encore instancié ou absent lors de l'init.";
} else {
    // Liaison des sous-systèmes de vol, immersion et sécurité
    [_unit, _plane] call ORA_fnc_cockpitImmersion;
    [_unit, _plane] call ORA_fnc_flightEffects;
    [_unit, _plane] call ORA_fnc_ejectionSystem;
};

// Ouverture du panneau tactique de lancement en début de partie
[] spawn {
    sleep 0.2;
    ["OPEN"] spawn ORA_fnc_mainMenu;
    titleCut ["", "BLACK IN", 1];
};

true
