params [
    ["_stringKey", "", [""]],
    ["_formatArgs", [], [[]]],
    ["_duration", 6, [0]], // Conservé pour la compatibilité, mais géré par le moteur via showSubtitle
    ["_playAudio", true, [true]],
    ["_speaker", "", [""]] // Nouveau paramètre optionnel
];

if (!hasInterface) exitWith {};
if (_stringKey isEqualTo "") exitWith {};

if (_playAudio && { isClass (missionConfigFile >> "CfgSounds" >> _stringKey) || isClass (configFile >> "CfgSounds" >> _stringKey) }) then {
    playSound _stringKey;
};

private _localizedText = localize _stringKey;
if (_localizedText isEqualTo "") then {
    _localizedText = _stringKey;
};

if (count _formatArgs > 0) then {
    _localizedText = format ([_localizedText] + _formatArgs);
};

// Détection automatique de l'émetteur si non fourni
if (_speaker isEqualTo "") then {
    if (_stringKey find "STR_Drone_" == 0) then {
        _speaker = localize "STR_LL_Radio_Speaker_Drone";
    } else {
        if (_stringKey find "STR_LL_Heli_" == 0 || _stringKey find "STR_TAG_Msg_" == 0) then {
            _speaker = localize "STR_LL_Radio_Speaker_AirSupport";
        } else {
            _speaker = localize "STR_LL_Radio_Speaker_HQ";
        };
    };
};

[_speaker, _localizedText] spawn BIS_fnc_showSubtitle;
