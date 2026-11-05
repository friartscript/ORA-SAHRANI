/*
    Auteur: ORA SQF Architect
    Description:
        Configure la dotation officielle de player_0 (pilote de chasse RACS).
        Conformément aux directives :
        - Base d'équipement des unités alliées au sol (INFO_EDITOR.md) : treillis MCCUU désert,
          gilet tactique JPC coyote, lunettes/foulard, JVN, fumigènes CSAR, grenades et trousses de soins.
        - Éléments aéronautiques spécifiques : casque d'aviation de chasse (visière & masque O2)
          et parachute dorsal de sauvetage (B_Parachute) indispensable pour la survie et l'éjection.
        - Arme de poing de survie en cabine (Glock 17) avec chargeurs dans le gilet.
        - Insigne officiel RACS (RACS_Badge).

    Paramètres:
        0: _pilot - Unité ciblée [Object, défaut: player]

    Retour:
        [Boolean] - true si équipé avec succès

    Exemple:
        [player] call ORA_fnc_initLoadout;
*/

params [
    ["_pilot", player, [objNull]]
];

if (isNull _pilot || {!local _pilot}) exitWith { false };

// Verrouillage pour identification stricte du pilote
_pilot setVariable ["ORA_isPilot", true, true];
_pilot setVariable ["ORA_racsEquipped", true, true];

// =============================================================================
// SÉLECTION DES ÉQUIPEMENTS (INFO_EDITOR.md + SPÉCIFICATION PILOTE DE CHASSE)
// =============================================================================

// 1. CASQUE D'AVIATEUR DE CHASSE (Priorité au casque de chasse avec visière et masque oxygène)
private _pilotHelmets = [
    "H_PilotHelmetFighter_I",
    "H_PilotHelmetFighter_B",
    "H_PilotHelmetFighter_I_E",
    "CUP_H_BAF_Helmet_Pilot",
    "CUP_H_USArmy_Helmet_Flight",
    "H_PilotHelmetHeli_B"
];
private _helmet = "H_PilotHelmetFighter_I";
{
    if (isClass (configFile >> "CfgWeapons" >> _x)) exitWith {
        _helmet = _x;
    };
} forEach _pilotHelmets;

// 2. TREILLIS DE COMBAT DES UNITÉS AU SOL (INFO_EDITOR.md)
private _uniforms = [
    "CUP_U_B_USMC_MCCUU_des_gloves",
    "CUP_U_B_USMC_MCCUU_des_roll_2_gloves",
    "CUP_U_B_USMC_MCCUU_des_roll_2_pads_gloves",
    "CUP_U_B_USMC_MCCUU_des_pads_gloves",
    "CUP_U_B_USMC_MCCUU_des_roll_pads_gloves",
    "CUP_U_B_USMC_MCCUU_des_roll_gloves",
    "CUP_U_B_USMC_MCCUU_des_roll_2",
    "CUP_U_B_USMC_MCCUU_des_roll_pads",
    "CUP_U_B_USMC_MCCUU_des_pads",
    "CUP_U_B_USMC_MCCUU_des_roll",
    "CUP_U_B_USMC_MCCUU_des"
];
private _validUniforms = _uniforms select { isClass (configFile >> "CfgWeapons" >> _x) };
private _uniform = if !(_validUniforms isEqualTo []) then {
    selectRandom _validUniforms
} else {
    "U_I_CombatUniform"
};

// 3. GILET PARE-BALLES JPC COYOTE DES UNITÉS AU SOL (INFO_EDITOR.md)
private _vests = [
    "CUP_V_JPC_medical_coy",
    "CUP_V_JPC_tl_coy",
    "CUP_V_JPC_weapons_coy",
    "CUP_V_JPC_communicationsbelt_coy",
    "CUP_V_JPC_Fastbelt_coy",
    "CUP_V_JPC_lightbelt_coy",
    "CUP_V_JPC_medicalbelt_coy",
    "CUP_V_JPC_tlbelt_coy",
    "CUP_V_JPC_weaponsbelt_coy"
];
private _validVests = _vests select { isClass (configFile >> "CfgWeapons" >> _x) };
private _vest = if !(_validVests isEqualTo []) then {
    selectRandom _validVests
} else {
    "V_PlateCarrierIA1_dgtl"
};

// 4. LUNETTES DE VOL (Uniquement compatibles aviation : pas de cagoule/foulard/barbe qui retirent le casque)
private _flightGoggles = ["G_Aviator"];
private _validGoggles = _flightGoggles select { isClass (configFile >> "CfgGlasses" >> _x) };

// 5. TÉLÉMÈTRE / JUMELLES (INFO_EDITOR.md)
private _binos = ["CUP_Vector21Nite", "CUP_LRTV", "CUP_SOFLAM", "Binocular"];
private _binocular = "Binocular";
{
    if (isClass (configFile >> "CfgWeapons" >> _x)) exitWith {
        _binocular = _x;
    };
} forEach _binos;

// 6. ARME DE POING DE SURVIE DU PILOTE
private _pistolClass = "hgun_P07_F";
private _magClass = "16Rnd_9x21_Mag";
if (isClass (configFile >> "CfgWeapons" >> "CUP_hgun_Glock17")) then {
    _pistolClass = "CUP_hgun_Glock17";
    _magClass = "CUP_17Rnd_9x19_glock17";
};

// =============================================================================
// APPLICATION DU CHARGEMENT
// =============================================================================

// Nettoyage complet préalable
removeAllWeapons _pilot;
removeAllItems _pilot;
removeAllAssignedItems _pilot;
removeUniform _pilot;
removeVest _pilot;
removeBackpack _pilot;
removeHeadgear _pilot;
removeGoggles _pilot;

// 1. Uniforme des unités au sol (MCCUU) et gilet JPC coyote (INFO_EDITOR.md)
_pilot forceAddUniform _uniform;
_pilot addVest _vest;

// 2. Parachute dorsal de sauvetage impératif (B_Parachute pour pilote de chasse)
_pilot addBackpack "B_Parachute";
if (backpack _pilot != "B_Parachute") then {
    removeBackpack _pilot;
    _pilot addBackpack "B_Parachute";
};

// 3. Lunettes de vol (G_Aviator) - appliquées AVANT le casque pour ne jamais écraser le couvre-chef
if !(_validGoggles isEqualTo []) then {
    _pilot addGoggles (selectRandom _validGoggles);
};

// 4. Casque d'aviateur impératif (avec vérification active et fallback)
private _helmetApplied = "";
{
    _pilot addHeadgear _x;
    if (headgear _pilot isEqualTo _x) exitWith {
        _helmetApplied = _x;
    };
} forEach _pilotHelmets;

// Si conflit avec lunettes, retirer les lunettes et forcer le casque d'aviation
if (_helmetApplied isEqualTo "" || {headgear _pilot isEqualTo ""}) then {
    removeGoggles _pilot;
    {
        _pilot addHeadgear _x;
        if (headgear _pilot isEqualTo _x) exitWith {
            _helmetApplied = _x;
        };
    } forEach _pilotHelmets;
};

// 5. Jumelles / Télémètre
_pilot addWeapon _binocular;

// 6. Vision nocturne NVG (INFO_EDITOR.md)
private _nvg = "NVGogglesB_blk_F";
if (!isClass (configFile >> "CfgWeapons" >> _nvg)) then { _nvg = "NVGoggles_INDEP"; };
_pilot linkItem _nvg;

// 7. Outils de navigation et communications
_pilot linkItem "ItemMap";
_pilot linkItem "ItemCompass";
_pilot linkItem "ItemWatch";
_pilot linkItem "ItemRadio";
_pilot linkItem "ItemGPS";

// 8. Trousse médicale de premiers soins (3x)
for "_i" from 1 to 3 do {
    _pilot addItemToUniform "FirstAidKit";
};

// 9. Fumigènes de signalisation CSAR et grenades (INFO_EDITOR.md)
_pilot addItemToVest "SmokeShellGreen";
_pilot addItemToVest "SmokeShellGreen";
_pilot addItemToVest "SmokeShell";
_pilot addItemToVest "SmokeShell";

private _frag = if (isClass (configFile >> "CfgMagazines" >> "CUP_HandGrenade_M67")) then { "CUP_HandGrenade_M67" } else { "HandGrenade" };
_pilot addItemToVest _frag;
_pilot addItemToVest _frag;

// 10. Arme de poing de dotation et chargeurs de réserve
_pilot addMagazine _magClass;
_pilot addWeapon _pistolClass;
for "_i" from 1 to 4 do {
    _pilot addItemToVest _magClass;
};
_pilot selectWeapon _pistolClass;

// 11. Insigne officiel RACS (CfgUnitInsignia)
[_pilot, "RACS_Badge"] call BIS_fnc_setUnitInsignia;

diag_log format [
    "[ORA-LOADOUT] [OK] Dotation du joueur (pilote) appliquée : Uniforme=%1, Gilet=%2, Casque=%3, Sac=B_Parachute, Arme=%4",
    _uniform, _vest, _helmet, _pistolClass
];

true
