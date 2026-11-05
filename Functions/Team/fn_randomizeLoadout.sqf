/*
    Author: Antigravity
    Description:
    Génère un loadout aléatoire basé sur INFO_PLAYERS.md pour l'unité donnée.
    Conserve l'arme principale et le pistolet, mais vide les inventaires (gilet/sac/uniforme).
    Ajoute 6 chargeurs principaux, 2 chargeurs secondaires, 2 FAK, 2 grenades, 2 fumigènes.

    Arguments:
    0: Object - L'unité à équiper (joueur local)

    Return:
    Bool
*/

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

// =======================================================
// LISTES D'ÉQUIPEMENTS
// =======================================================

private _uniforms = [
    "amf_uniform_01_NG_DA_HX",
    "amf_uniform_01_DA_HX",
    "amf_uniform_01_RE_DA_HX",
    "amf_uniform_01_RE_NG_DA_HX",
    "amf_uniform_01_NG_DA_LowaZephyr",
    "amf_uniform_01_DA_MD",
    "amf_uniform_01_RE_NG_DA_MD"
];

private _headgears = [
    "AMF_OPSCORE2_TAN",
    "AMF_OPSCORE2_TAN_2",
    "AMF_OPSCORE2_TAN2",
    "AMF_OPSCORE3_TAN",
    "AMF_OPSCORE_TAN",
    "AMF_OPSCORE_TAN2",
    "AMF_FELIN_L03_TAN",
    "AMF_FELIN_05_TAN"
];

private _backpacks = [
    "AMF_rush24_TAN",
    "AMF_FELIN_BACKPACK",
    "AMF_FELIN_BACKPACK_LIGHT_TDF"
];
private _radioBackpack = "AMF_FELIN_BACKPACK_Radio";

private _goggles = [
    "G_Aviator",
    "rhs_googles_black",
    "G_Bandanna_tan",
    "G_Combat",
    "G_Lowprofile",
    "rhsusf_shemagh_gogg_tan",
    "rhsusf_shemagh2_gogg_tan"
];

private _vests = [
    "amf_SMB_ART",
    "amf_SMB_AUXS",
    "amf_SMB_GREN",
    "amf_SMB_TP_HK417"
];

// --- SÉCURITÉ : Filtrage des classnames invalides ---
// Si l'utilisateur a fait une faute de frappe dans INFO_PLAYERS.md, la classe est ignorée.
_uniforms = _uniforms select { isClass (configFile >> "CfgWeapons" >> _x) };
_headgears = _headgears select { isClass (configFile >> "CfgWeapons" >> _x) };
_backpacks = _backpacks select { isClass (configFile >> "CfgVehicles" >> _x) };
_vests = _vests select { isClass (configFile >> "CfgWeapons" >> _x) };

// Fallback de sécurité si tous les gilets fournis sont invalides
if (count _vests == 0) then {
    _vests = ["amf_SMB_LEADER"];
};

if (count _uniforms == 0) exitWith { false }; // Impossible de continuer sans tenue

private _binocular = "AMF_APX_M241";
private _nvg = "AMF_ONYX_NVG";
private _patch = "AMF_FRANCE_HV";

// =======================================================
// SAUVEGARDE DES ARMES ET CHARGEURS (AVANT NETTOYAGE)
// =======================================================

private _primaryWeapon = primaryWeapon _unit;
private _handgunWeapon = handgunWeapon _unit;

// On récupère les chargeurs qu'il possède DÉJÀ dans son inventaire de base
private _existingMags = magazines _unit;
private _primaryMagClass = "";
private _handgunMagClass = "";

{
    if (_primaryMagClass == "" && { _x in (compatibleMagazines _primaryWeapon) }) then {
        _primaryMagClass = _x;
    };
    if (_handgunMagClass == "" && { _x in (compatibleMagazines _handgunWeapon) }) then {
        _handgunMagClass = _x;
    };
} forEach _existingMags;

// Fallback robuste au cas où il n'avait pas de chargeur sur lui
if (_primaryMagClass == "" && _primaryWeapon != "") then {
    private _compat = compatibleMagazines _primaryWeapon;
    if (count _compat > 0) then { _primaryMagClass = _compat select 0; };
};
if (_handgunMagClass == "" && _handgunWeapon != "") then {
    private _compat = compatibleMagazines _handgunWeapon;
    if (count _compat > 0) then { _handgunMagClass = _compat select 0; };
};

// =======================================================
// NETTOYAGE DES CONTENEURS ET ÉQUIPEMENTS
// =======================================================


// On retire d'abord l'uniforme, ce qui vide aussi son contenu
removeUniform _unit;
removeVest _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeGoggles _unit;

// On retire les lunettes NVG et jumelles s'il en a pour les remplacer
_unit unassignItem (hmd _unit);
_unit removeItem (hmd _unit);

if (binocular _unit != "") then {
    _unit removeWeapon (binocular _unit);
};

// =======================================================
// ATTRIBUTION DES NOUVEAUX ÉQUIPEMENTS (ALÉATOIRES)
// =======================================================

// On distribue les tenues de façon séquentielle pour FORCER la diversité (au lieu du hasard)
if (isNil "LL_UniformCounter") then { LL_UniformCounter = 0; };
private _newUniform = _uniforms select (LL_UniformCounter % (count _uniforms));
LL_UniformCounter = LL_UniformCounter + 1;

private _newVest = selectRandom _vests;
private _newHeadgear = selectRandom _headgears;
private _newGoggle = selectRandom _goggles;

// Rôle spécifique (Player_2 = Radio)
private _isRadio = (str _unit == "Player_2" || typeOf _unit == "B_AMF_UBAS_DA_Radio_HK416");
private _newBackpack = if (_isRadio) then { _radioBackpack } else { selectRandom _backpacks };

// Application de l'habillement
_unit forceAddUniform _newUniform;
_unit addVest _newVest;
_unit addBackpack _newBackpack;
_unit addHeadgear _newHeadgear;
_unit addGoggles _newGoggle;

// Ajout des objets fixes
_unit addWeapon _binocular;
_unit linkItem _nvg;
_unit setVariable ["bis_fnc_setUnitInsignia_class", _patch, true];
[_unit, _patch] call BIS_fnc_setUnitInsignia;

// =======================================================
// REMPLISSAGE DE L'INVENTAIRE (Priorité absolue aux munitions)
// =======================================================

// 1. Chargeurs Arme Principale (6)
if (_primaryMagClass != "") then {
    _unit addMagazines [_primaryMagClass, 6];
};

// 2. Chargeurs Pistolet (2)
if (_handgunMagClass != "") then {
    _unit addMagazines [_handgunMagClass, 2];
};

// 3. Soins et Grenades (2 FirstAidKit, 2 Grenades, 2 Fumigènes)
for "_i" from 1 to 2 do {
    _unit addItem "FirstAidKit";
    _unit addItem "HandGrenade";
    _unit addItem "SmokeShell";
};

// On s'assure que l'arme est bien chargée avec son chargeur
if (_primaryWeapon != "" && _primaryMagClass != "") then {
    _unit addPrimaryWeaponItem _primaryMagClass;
};
if (_handgunWeapon != "" && _handgunMagClass != "") then {
    _unit addHandgunItem _handgunMagClass;
};

// On sélectionne l'arme principale
_unit selectWeapon _primaryWeapon;

true
