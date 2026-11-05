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

// ============================================================================
// DÉSACTIVATION COMPLÈTE DU SYSTÈME DE CHAT ET DES LOGS DU JEU
// ============================================================================
showChat false;
enableRadio false;
enableSentences false;
0 fadeRadio 0;

_unit addEventHandler ["Respawn", {
    showChat false;
    enableRadio false;
    enableSentences false;
    0 fadeRadio 0;
}];

// Écran noir initial le temps d'ouvrir le menu
titleCut ["", "BLACK FADED", 999];

// Marquage prioritaire de l'unité joueur comme pilote de chasse officiel
_unit setVariable ["ORA_isPilot", true, true];

// Vérification de conformité avec l'éditeur (INFO_EDITOR.md)
private _expectedPlayer = missionNamespace getVariable ["player_0", objNull];
if (!isNull _expectedPlayer && {!(_unit isEqualTo _expectedPlayer)}) then {
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
} else {
    // Liaison des sous-systèmes de vol, immersion et sécurité
    [_unit, _plane] call ORA_fnc_cockpitImmersion;
    [_unit, _plane] call ORA_fnc_flightEffects;
    [_unit, _plane] call ORA_fnc_ejectionSystem;
    [_plane, true] call ORA_fnc_weaponGuidance;

    // Action d'appel direct dans l'aéronef en cas de besoin
    _plane addAction [
        format ["<t color='#00d0ff'>[0-8-1] %1</t>", localize "STR_ORA_SUPPORT_REFUEL_TITLE"],
        { [] spawn ORA_fnc_callTanker; },
        nil,
        1.5,
        false,
        true,
        "",
        "alive _target && {vehicle _this == _target}"
    ];
};

// Enregistrement officiel du menu Support Radio 0-8-1 (Ravitailleur C-130J)
if (!isNil "BIS_fnc_addCommMenuItem") then {
    [_unit, "ORA_RefuelSupport", nil, nil, ""] call BIS_fnc_addCommMenuItem;
};

// Ouverture du panneau tactique de lancement en début de partie
[] spawn {
    sleep 0.2;
    ["OPEN"] spawn ORA_fnc_mainMenu;
    titleCut ["", "BLACK IN", 1];
};

true
