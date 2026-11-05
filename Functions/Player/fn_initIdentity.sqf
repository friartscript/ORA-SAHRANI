/*
    Auteur: ORA SQF Architect
    Description:
        Initialise l'identité militaire du pilote de chasse (player_0).
        Attribue le grade de Capitaine, une voix anglophone claire compatible
        avec les protocoles radio et l'indicatif d'escadrille "Victor-One".
    Paramètres:
        0: _pilot - Unité ciblée (défaut: player_0) [Object]
    Retour:
        [Boolean] - true si l'identité est configurée
    Exemple:
        [player] call ORA_fnc_initIdentity;
*/
params [
    ["_pilot", objNull, [objNull]]
];

if (isNull _pilot) then {
    _pilot = missionNamespace getVariable ["player_0", player];
};

if (isNull _pilot || {!local _pilot}) exitWith { false };

// Visage pilote d'intervention
private _faces = [
    "WhiteHead_01", "WhiteHead_02", "WhiteHead_03", "WhiteHead_04", "WhiteHead_05",
    "WhiteHead_06", "WhiteHead_07", "WhiteHead_08", "WhiteHead_09", "WhiteHead_10",
    "AfricanHead_01", "AfricanHead_02", "AsianHead_A3_01", "PersianHead_A3_01"
];
private _face = selectRandom _faces;

// Voix radio anglophone martiale
private _speakers = [
    "Male01ENG", "Male02ENG", "Male03ENG", "Male04ENG",
    "Male05ENG", "Male06ENG", "Male07ENG", "Male08ENG"
];
private _speaker = selectRandom _speakers;
private _pitch = 0.95 + random 0.10;

// Application des attributs
_pilot setFace _face;
_pilot setSpeaker _speaker;
_pilot setPitch _pitch;

// Attribution du grade officiel
_pilot setUnitRank "CAPTAIN";

// Sauvegarde dans les variables d'état
_pilot setVariable ["ORA_pilotCallsign", "Victor-One", true];
_pilot setVariable ["ORA_pilotIdentitySet", true, true];

true
