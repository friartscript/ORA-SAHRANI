/*
    Auteur: ORA SQF Architect
    Description:
        Active les écouteurs d'événements immersifs de cockpit pour l'appareil plane_0
        et le joueur player_0 (alertes RWR missile, secousses aux tirs, etc.).
    Paramètres:
        0: _pilot - Unité du joueur [Object]
        1: _plane - Vecteur aérien assigné [Object]
    Retour:
        [Boolean] - true si les écouteurs sont installés
    Exemple:
        [player, plane_0] call ORA_fnc_cockpitImmersion;
*/
params [
    ["_pilot", objNull, [objNull]],
    ["_plane", objNull, [objNull]]
];

if (isNull _plane) exitWith { false };

// 1. Détection de tir d'armement lourd (secousses cockpit au départ canon/missile)
_plane addEventHandler ["Fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    
    // Secousse légère réaliste lors de la détente des armes
    if (cameraView isEqualTo "INTERNAL") then {
        addCamShake [0.8, 0.4, 30];
    };
}];

// 2. Alerte RWR de verrouillage et missile entrant
_plane addEventHandler ["IncomingMissile", {
    params ["_target", "_ammo", "_vehicle", "_instigator"];
    
    // Alerte sonore d'urgence
    playSoundUI ["ORA_Warning_Beep", 1.2, 1.3];
    addCamShake [1.8, 1.5, 25];
    
    // Annonce radio d'alerte défensive
    [
        "SYSTEM",
        localize "STR_ORA_Alert_MissileInbound",
        "STR_ORA_Alert_MissileInbound"
    ] call ORA_fnc_radioMsg;
}];

// 3. Détection des transitions d'embarquement / débarquement
_pilot addEventHandler ["GetInMan", {
    params ["_unit", "_role", "_vehicle", "_turret"];
    if (_vehicle == (missionNamespace getVariable ["plane_0", objNull])) then {
        ["ATC", localize "STR_ORA_Radio_CockpitReady", "STR_ORA_Radio_CockpitReady"] call ORA_fnc_radioMsg;
    };
}];

true

