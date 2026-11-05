/*
    Auteur: ORA SQF Architect
    Description:
        Surveille et applique la condition impérative de défaite liée à l'intégrité du cockpit.
        Toute éjection ou abandon de l'appareil assigné (plane_0) par le pilote
        provoque l'annulation immédiate de la sortie et la défaite de la mission.
    Paramètres:
        0: _pilot - Le joueur pilote [Object, défaut: player]
        1: _plane - L'appareil assigné [Object, défaut: plane_0]
    Retour:
        [Boolean] - true si la surveillance a été armée avec succès
    Exemple:
        [player, plane_0] call ORA_fnc_cockpitEgressForfeit;
*/

params [
    ["_pilot", player, [objNull]],
    ["_plane", objNull, [objNull]]
];

if (!hasInterface) exitWith { false };
if (isNull _pilot || {!local _pilot}) exitWith { false };

if (isNull _plane) then {
    _plane = missionNamespace getVariable ["plane_0", objNull];
};

if (isNull _plane) exitWith {
    diag_log "[ORA-FLIGHT] [ERREUR] plane_0 est null. Impossible d'armer la surveillance d'éjection.";
    false
};

// Empêcher l'armement multiple
if (_pilot getVariable ["ORA_cockpitMonitorArmed", false]) exitWith { true };
_pilot setVariable ["ORA_cockpitMonitorArmed", true];

diag_log "[ORA-FLIGHT] [INIT] Surveillance du cockpit armée : Abandon interdit (Condition de défaite).";

// 1. Écouteur GetOutMan sur le joueur
_pilot addEventHandler ["GetOutMan", {
    params ["_unit", "_role", "_vehicle", "_turret"];

    private _assignedPlane = missionNamespace getVariable ["plane_0", objNull];

    // Si le pilote quitte son avion ou tout aéronef après le lancement
    if (_vehicle isEqualTo _assignedPlane || {_vehicle isKindOf "Plane"}) then {
        [_unit, _vehicle] spawn {
            params ["_unit", "_vehicle"];

            // Éviter l'exécution concurrente multiple
            if (missionNamespace getVariable ["ORA_forfeitExecuted", false]) exitWith {};
            missionNamespace setVariable ["ORA_forfeitExecuted", true, true];

            diag_log "[ORA-FLIGHT] [DÉFAITE] Extraction / Éjection cockpit détectée. Sortie annulée !";

            // Alarme critique et secousse d'écran
            playSoundUI ["ORA_Warning_Beep", 1.5, 0.8];
            addCamShake [3.0, 3.5, 25];

            // Transmission radio d'alerte de la Tour Sahrani
            [
                "ATC",
                localize "STR_ORA_Radio_CockpitAbandoned",
                "ORA_Warning_Beep"
            ] call ORA_fnc_radioMsg;

            // Titre rouge vif d'alerte critique à l'écran
            titleText [
                localize "STR_ORA_Alert_CockpitForfeit_Screen",
                "PLAIN",
                0.3,
                true,
                true
            ];

            // Fondu au noir cinématique puis clôture de la mission en défaite
            sleep 2.5;
            titleCut ["", "BLACK OUT", 1.0];
            sleep 1.2;

            ["EndCockpitForfeit", false, 0] call BIS_fnc_endMission;
        };
    };
}];

// 2. Écouteur de secours GetOut directement sur l'appareil plane_0
_plane addEventHandler ["GetOut", {
    params ["_vehicle", "_role", "_unit", "_turret"];

    if (_unit isEqualTo player) then {
        if !(missionNamespace getVariable ["ORA_forfeitExecuted", false]) then {
            missionNamespace setVariable ["ORA_forfeitExecuted", true, true];

            [_unit, _vehicle] spawn {
                params ["_unit", "_vehicle"];
                playSoundUI ["ORA_Warning_Beep", 1.5, 0.8];
                addCamShake [3.0, 3.5, 25];

                [
                    "ATC",
                    localize "STR_ORA_Radio_CockpitAbandoned",
                    "ORA_Warning_Beep"
                ] call ORA_fnc_radioMsg;

                titleText [
                    localize "STR_ORA_Alert_CockpitForfeit_Screen",
                    "PLAIN",
                    0.3,
                    true,
                    true
                ];

                sleep 2.5;
                titleCut ["", "BLACK OUT", 1.0];
                sleep 1.2;

                ["EndCockpitForfeit", false, 0] call BIS_fnc_endMission;
            };
        };
    };
}];

true

