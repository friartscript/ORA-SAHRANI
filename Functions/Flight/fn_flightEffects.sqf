/*
    Auteur: ORA SQF Architect
    Description:
        Gère les effets de dynamique de vol et de facteurs de charge (G-force, secousses
        à haute vitesse et turbulences de relief) de façon ultra-optimisée via EachFrame.
    Paramètres:
        0: _pilot - Le joueur pilote [Object]
        1: _plane - L'appareil assigné [Object]
    Retour:
        [Boolean] - true si le gestionnaire est activé
    Exemple:
        [player, plane_0] call ORA_fnc_flightEffects;
*/
params [
    ["_pilot", player, [objNull]],
    ["_plane", objNull, [objNull]]
];

if (!hasInterface) exitWith { false };
if (isNull _plane) exitWith { false };

// Suppression d'un éventuel gestionnaire déjà actif
private _existingHandler = missionNamespace getVariable ["ORA_flightHandlerId", -1];
if (_existingHandler != -1) then {
    removeMissionEventHandler ["EachFrame", _existingHandler];
};

// Variable d'état pour calcul d'accélération
_plane setVariable ["ORA_lastVelocity", velocity _plane];

private _handlerId = addMissionEventHandler ["EachFrame", {
    private _plane = missionNamespace getVariable ["plane_0", objNull];
    if (isNull _plane || {!alive _plane}) exitWith {
        private _id = missionNamespace getVariable ["ORA_flightHandlerId", -1];
        if (_id != -1) then { removeMissionEventHandler ["EachFrame", _id]; };
    };

    // Actif uniquement si le joueur est dans le cockpit
    if (vehicle player != _plane) exitWith {};

    private _speedKmh = speed _plane;
    private _currentVel = velocity _plane;
    private _lastVel = _plane getVariable ["ORA_lastVelocity", _currentVel];
    _plane setVariable ["ORA_lastVelocity", _currentVel];

    // Estimation du différentiel d'accélération verticale/latérale
    private _deltaAcc = vectorMagnitude (_currentVel vectorDiff _lastVel);

    // Effet de secousse sous facteur de charge (> 4.5G équivalent moteur)
    if (_deltaAcc > 2.2 && {_speedKmh > 350}) then {
        addCamShake [0.7, 0.2, 18];
    };

    // Turbulences de basse altitude au-dessus du relief de Sahrani
    private _altAgl = (getPosVisual _plane) select 2;
    if (_altAgl < 60 && {_speedKmh > 600} && {cameraView isEqualTo "INTERNAL"}) then {
        addCamShake [0.4, 0.15, 22];
    };
}];

missionNamespace setVariable ["ORA_flightHandlerId", _handlerId];

true

