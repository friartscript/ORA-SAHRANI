/*
    Auteur: ORA SQF Architect
    Description:
        Configure la dotation officielle de pilote de chasse pour player_0.
        Attribue un casque de vol avec visière/masque à oxygène, une combinaison
        ignifugée, un parachute de sauvetage dorsal (crucial pour l'éjection),
        un pistolet de service et le kit de survie/signalisation CSAR.
    Paramètres:
        0: _pilot - Unité à équiper (défaut: player) [Object]
    Retour:
        [Boolean] - true si équipé avec succès
    Exemple:
        [player] call ORA_fnc_initLoadout;
*/
params [
    ["_pilot", player, [objNull]]
];

if (isNull _pilot || {!local _pilot}) exitWith { false };

// Sélection adaptative du casque de pilote de chasse (Vanilla & CUP compatible)
private _helmets = [
    "H_PilotHelmetFighter_B",
    "H_PilotHelmetFighter_I",
    "H_PilotHelmetFighter_I_E",
    "CUP_H_BAF_Helmet_Pilot",
    "CUP_H_USArmy_Helmet_Flight",
    "H_PilotHelmetHeli_B"
];
private _helmet = "H_PilotHelmetFighter_B";
{
    if (isClass (configFile >> "CfgWeapons" >> _x)) exitWith {
        _helmet = _x;
    };
} forEach _helmets;

// Sélection adaptative de la combinaison de vol (Flight Suit)
private _uniforms = [
    "U_B_PilotCoveralls",
    "U_I_pilotCoveralls",
    "U_I_E_Uniform_01_coveralls_F",
    "CUP_U_B_USArmy_PilotOverall",
    "CUP_U_B_USMC_PilotOverall"
];
private _uniform = "U_B_PilotCoveralls";
{
    if (isClass (configFile >> "CfgWeapons" >> _x)) exitWith {
        _uniform = _x;
    };
} forEach _uniforms;

// Sélection du ceinturon / harnais léger de cockpit
private _vests = [
    "V_Rangemaster_belt",
    "V_BandollierB_blk",
    "V_BandollierB_rgr",
    "CUP_V_B_PilotVest",
    "V_TacVest_blk"
];
private _vest = "V_Rangemaster_belt";
{
    if (isClass (configFile >> "CfgWeapons" >> _x)) exitWith {
        _vest = _x;
    };
} forEach _vests;

// Arme de poing de dotation et munitions
private _pistolClass = "hgun_P07_F";
private _magClass = "16Rnd_9x21_Mag";

if (isClass (configFile >> "CfgWeapons" >> "CUP_hgun_Glock17")) then {
    _pistolClass = "CUP_hgun_Glock17";
    _magClass = "CUP_17Rnd_9x19_glock17";
};

// Nettoyage complet préalable
removeAllWeapons _pilot;
removeAllItems _pilot;
removeAllAssignedItems _pilot;
removeUniform _pilot;
removeVest _pilot;
removeBackpack _pilot;
removeHeadgear _pilot;
removeGoggles _pilot;

// 1. Équipement vestimentaire
_pilot forceAddUniform _uniform;
_pilot addVest _vest;
_pilot addHeadgear _helmet;

// 2. Parachute de secours dorsal (Indispensable pour l'éjection de plane_0)
_pilot addBackpack "B_Parachute";

// 3. Armement secondaire (Survie)
_pilot addMagazine _magClass;
_pilot addWeapon _pistolClass;
for "_i" from 1 to 3 do {
    _pilot addMagazine _magClass;
};

// 4. Équipements de navigation, avionique et survie CSAR
_pilot addItem "FirstAidKit";
_pilot addItem "FirstAidKit";

// Fumigènes de signalisation pour récupération d'urgence (CSAR)
_pilot addItem "SmokeShellGreen";
_pilot addItem "SmokeShellOrange";
_pilot addItem "Chemlight_green";

// Éléments reliés
_pilot linkItem "ItemMap";
_pilot linkItem "ItemCompass";
_pilot linkItem "ItemWatch";
_pilot linkItem "ItemRadio";
_pilot linkItem "ItemGPS";

// Lunettes de vision nocturne intégrées au casque
if (isClass (configFile >> "CfgWeapons" >> "NVGoggles")) then {
    _pilot linkItem "NVGoggles";
};

// Application du badge d'escadron officiel
[_pilot, "RACS_Badge"] spawn {
    params ["_unit", "_insignia"];
    sleep 0.5;
    if (alive _unit) then {
        [_unit, _insignia] call BIS_fnc_setUnitInsignia;
    };
};

_pilot setVariable ["ORA_pilotLoadoutApplied", true, true];

diag_log format ["[ORA-LOADOUT] Pilote %1 équipé avec succès : %2 | %3 | %4", name _pilot, _helmet, _uniform, _vest];

true
