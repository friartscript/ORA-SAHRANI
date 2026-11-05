/*
    Auteur: ORA SQF Architect
    Description:
        Diffuse un message radio militaire immersif avec signal sonore,
        formatage d'indicatif d'appel et affichage diégétique.
    Paramètres:
        0: _sender - Indicatif de l'émetteur (ex: "ATC", "AWACS", "COMMAND") [String]
        1: _message - Contenu textuel du message [String]
        2: _sound - Classe de son radio à jouer (optionnel, défaut: "ORA_Radio_Click") [String]
    Retour:
        [Boolean] - true si affiché
    Exemple:
        ["AWACS", "Bandit direct 0-4-0, 15 nautiques, Angels 12."] call ORA_fnc_radioMsg;
*/
params [
    ["_sender", "RADIO", [""]],
    ["_message", "", [""]],
    ["_sound", "ORA_Radio_Click", [""]]
];

if (!hasInterface) exitWith { false };
if (_message isEqualTo "") exitWith { false };

// Bip d'ouverture radio diégétique
if (_sound != "") then {
    playSoundUI [_sound, 1.0, 1.0];
};

// Choix chromatique selon l'émetteur pour lisibilité militaire
private _senderColor = switch (toUpper _sender) do {
    case "AWACS":    { "#ffd700" }; // Or tactique
    case "ATC":      { "#00d0ff" }; // Bleu clair contrôle
    case "COMMAND":  { "#ff4444" }; // Rouge commandement
    case "SYSTEM":   { "#00ff88" }; // Vert système de bord
    default          { "#cccccc" }; // Gris neutre
};

// Affichage sous-titre formaté militaire
private _formattedText = format [
    "<t font='PuristaMedium' size='0.8' color='%1'>[%2]</t> <t font='PuristaLight' size='0.75' color='#ffffff'>%3</t>",
    _senderColor,
    toUpper _sender,
    _message
];

[_formattedText, 0, 0.85, 4, 0.3, 0, 999] spawn BIS_fnc_dynamicText;

// Trace dans le journal de chat système
systemChat format ["[%1] %2", toUpper _sender, _message];

true

