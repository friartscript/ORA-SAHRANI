/*
    Auteur: ORA SQF Architect
    Description:
        Surveille l'intégrité structurelle de plane_0 via l'Event Handler Dammaged.
        En cas d'avarie critique, déclenche les avertisseurs et gère le cas de survie/défaillance.
    Paramètres:
        0: _pilot - Le joueur pilote [Object]
        1: _plane - L'appareil assigné [Object]
    Retour:
        [Boolean] - true si le système de surveillance est armé
    Exemple:
        [player, plane_0] call ORA_fnc_ejectionSystem;
*/
params [
    ["_pilot", player, [objNull]],
    ["_plane", objNull, [objNull]]
];

if (isNull _plane) exitWith { false };

// Surveillance des dégâts critiques
_plane addEventHandler ["Dammaged", {
    params ["_unit", "_selection", "_damage", "_hitIndex", "_hitPoint", "_shooter", "_projectile"];
    
    // Si l'appareil subit des avaries graves (> 80%) et que le joueur est aux commandes
    if (_damage > 0.8 && {alive _unit} && {vehicle player == _unit}) then {
        if !(_unit getVariable ["ORA_alarmTriggered", false]) then {
            _unit setVariable ["ORA_alarmTriggered", true];
            
            // Alerte sonore et visuelle
            playSoundUI ["ORA_Warning_Beep", 1.4, 1.0];
            addCamShake [2.5, 3.0, 20];
            
            [
                "SYSTEM",
                localize "STR_ORA_Alert_CriticalDamage",
                "ORA_Warning_Beep"
            ] call ORA_fnc_radioMsg;
        };
    };
}];

// Gestion de la destruction du vecteur
_plane addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];
    
    // Si le joueur a survécu à la destruction (s'est éjecté ou a sauté)
    if (alive player && {vehicle player != _unit}) then {
        [
            "ATC",
            localize "STR_ORA_Radio_EjectedSafe"
        ] call ORA_fnc_radioMsg;
    };
}];

// Surveillance de la mort du joueur
_pilot addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];
    ["EndKilled", false, 4] spawn BIS_fnc_endMission;
}];

true

