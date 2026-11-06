/*
    Auteur: ORA SQF Architect
    Description:
        Diffuse un message radio militaire immersif avec signal sonore,
        formatage d'indicatif d'appel et affichage diégétique.
    Paramètres:
        0: _sender - Indicatif de l'émetteur (ex: "ATC", "AWACS", "COMMAND", "OVERLORD", "TANKER") [String]
        1: _message - Contenu textuel du message [String]
        2: _sound - Classe de son radio/TTS à jouer (optionnel, défaut: "ORA_Radio_Click") [String]
    Retour:
        [Boolean] - true si affiché
    Exemple:
        ["OVERLORD", "Victor-One, engage the convoy at grid 1123.", "STR_ORA_Task_Ground_Order"] call ORA_fnc_radioMsg;
*/
params [
    ["_sender", "RADIO", [""]],
    ["_message", "", [""]],
    ["_sound", "ORA_Radio_Click", [""]]
];

if (!hasInterface) exitWith { false };
if (_message isEqualTo "") exitWith { false };

// Diffusion sonore unique et propre (aucun doublon ni écho)
if (_sound != "") then {
    playSoundUI [_sound, 1.2, 1.0, false];
};

// Choix chromatique selon l'émetteur pour lisibilité militaire
private _senderColor = switch (toUpper _sender) do {
    case "AWACS":    { "#ffd700" }; // Or tactique
    case "ATC":      { "#00d0ff" }; // Bleu clair contrôle
    case "COMMAND":  { "#ff4444" }; // Rouge commandement
    case "SYSTEM":   { "#00ff88" }; // Vert système de bord
    case "OVERLORD": { "#ffaa00" }; // Orange doré Overlord QG
    case "TANKER":   { "#00d0ff" }; // Bleu clair ravitailleur
    default          { "#cccccc" }; // Gris neutre
};

// Affichage sous-titre formaté militaire discret et épuré en bas d'écran
private _formattedText = format [
    "<t font='PuristaMedium' size='0.46' color='%1'>[%2]</t> <t font='PuristaLight' size='0.42' color='#ffffff'>%3</t>",
    _senderColor,
    toUpper _sender,
    _message
];

[_formattedText, 0, 0.94, 3.5, 0.25, 0, 999] spawn BIS_fnc_dynamicText;

true
