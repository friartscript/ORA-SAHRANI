/*
    Auteur: ORA SQF Architect
    Description:
        Applique la dotation d'équipement officielle du Royal Army Corps of Sahrani (RACS)
        conforme aux spécifications de INFO_EDITOR.md à l'ensemble des unités indépendantes.
        Préserve les armes et accessoires existants de l'unité tout en harmonisant les uniformes,
        gilets, casques, sacs, JVN, jumelles et insignes officiels.
        Exclut formellement le joueur (pilote de chasse avec casque d'aviation).
        Installe un écouteur EntityCreated pour équiper automatiquement toute unité indépendante
        générée ultérieurement au cours de la mission.

    Paramètres:
        0: _targetUnit - (Optionnel) Unité individuelle à équiper [Object, défaut: objNull]

    Retour:
        [Boolean] - true si l'opération a réussi

    Exemples:
        // Équiper toutes les unités indépendantes de la carte + activer l'auto-équipement futur :
        [] call ORA_fnc_applyRACSLoadout;

        // Équiper une unité spécifique lors d'un spawn dynamique :
        [_mySpawnedUnit] call ORA_fnc_applyRACSLoadout;
*/

params [
    ["_targetUnit", objNull, [objNull]]
];

// Fonction interne d'équipement d'une unité RACS individuelle
private _fnc_equipSingleRACS = {
    params ["_unit"];

    if (isNull _unit || {!alive _unit}) exitWith { false };

    // --- SÉCURITÉ ABSOLUE : EXCLUSION DU JOUEUR PILOTE ---
    private _isPilot = (_unit isEqualTo player) 
        || {_unit isEqualTo (missionNamespace getVariable ["player_0", objNull])} 
        || {isPlayer _unit} 
        || {(vehicleVarName _unit) isEqualTo "player_0"} 
        || {(str _unit) find "player_0" >= 0} 
        || {_unit getVariable ["ORA_isPilot", false]};

    if (_isPilot) exitWith { false };

    // L'unité doit appartenir au camp indépendant (RACS)
    if (side (group _unit) != independent) exitWith { false };

    // Empêcher la réapplication multiple sur une unité déjà équipée
    if (_unit getVariable ["ORA_racsEquipped", false]) exitWith { false };
    _unit setVariable ["ORA_racsEquipped", true, true];

    // Sauvegarde des armes actuelles et de leurs accessoires
    private _primaryWeapon   = primaryWeapon _unit;
    private _primaryItems    = primaryWeaponItems _unit;
    private _handgunWeapon   = handgunWeapon _unit;
    private _handgunItems    = handgunItems _unit;
    private _secondaryWeapon = secondaryWeapon _unit;
    private _secondaryItems  = secondaryWeaponItems _unit;

    // Détection des chargeurs compatibles pour les armes conservées
    private _primaryMag = "";
    if (_primaryWeapon != "") then {
        private _compat = compatibleMagazines _primaryWeapon;
        if (count _compat > 0) then { _primaryMag = _compat select 0; };
    };

    private _handgunMag = "";
    if (_handgunWeapon != "") then {
        private _compat = compatibleMagazines _handgunWeapon;
        if (count _compat > 0) then { _handgunMag = _compat select 0; };
    };

    // Nettoyage complet des anciens conteneurs et équipements de tête
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    // Retirer jumelles et optiques de vision nocturne antérieures
    _unit removeWeapon (binocular _unit);
    _unit unassignItem (hmd _unit);
    _unit removeItem (hmd _unit);

    // =========================================================================
    // CATALOGUE DES ÉQUIPEMENTS RACS (Source contractuelle: INFO_EDITOR.md)
    // =========================================================================

    private _uniforms = [
        "CUP_U_B_USMC_MCCUU_des_gloves",
        "CUP_U_B_USMC_MCCUU_des_roll_2",
        "CUP_U_B_USMC_MCCUU_des_roll_2_gloves",
        "CUP_U_B_USMC_MCCUU_des_roll_pads",
        "CUP_U_B_USMC_MCCUU_des_roll_2_pads_gloves",
        "CUP_U_B_USMC_MCCUU_des_pads",
        "CUP_U_B_USMC_MCCUU_des_pads_gloves",
        "CUP_U_B_USMC_MCCUU_des_roll",
        "CUP_U_B_USMC_MCCUU_des_roll_gloves",
        "CUP_U_B_USMC_MCCUU_des_roll_pads",
        "CUP_U_B_USMC_MCCUU_des_roll_pads_gloves",
        "CUP_U_B_USMC_MCCUU_des"
    ];

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

    private _headgears = [
        "CUP_H_OpsCore_Tan_SF",
        "CUP_H_OpsCore_Tan",
        "CUP_H_OpsCore_Tan_NohS",
        "CUP_H_OpsCore_Grey_SF",
        "CUP_H_OpsCore_Grey",
        "CUP_H_OpsCore_Grey_NohS"
    ];

    private _backpacks = [
        "CUP_B_AssaultPack_Coyote",
        "B_assaultPack_cbr",
        "B_Kitbag_cbr"
    ];

    private _goggles = [
        "CUP_G_Tan_Scarf_Shades_GPSCombo_Beard",
        "CUP_G_Tan_Scarf_Shades_GPS_Beard",
        "CUP_G_Tan_Scarf_GPS",
        "CUP_G_TK_RoundGlasses_blk",
        "CUP_G_Oakleys_Drk",
        "CUP_G_Scarf_Face_Tan",
        "G_Aviator",
        "CUP_G_ESS_KHK_Scarf_Tan_GPS_Beard",
        "CUP_G_ESS_KHK_Facewrap_Tan",
        "G_Bandana_khk"
    ];

    private _binoculars = [
        "CUP_LRTV",
        "CUP_Vector21Nite",
        "CUP_SOFLAM"
    ];

    // Filtrage dynamique pour garantir la validité des classes d'addons
    private _validUniforms = _uniforms select { isClass (configFile >> "CfgWeapons" >> _x) };
    if (_validUniforms isEqualTo []) then { _validUniforms = ["U_I_CombatUniform"]; };

    private _validVests = _vests select { isClass (configFile >> "CfgWeapons" >> _x) };
    if (_validVests isEqualTo []) then { _validVests = ["V_PlateCarrierIA1_dgtl"]; };

    private _validHeadgears = _headgears select { isClass (configFile >> "CfgWeapons" >> _x) };
    if (_validHeadgears isEqualTo []) then { _validHeadgears = ["H_HelmetIA"]; };

    private _validBackpacks = _backpacks select { isClass (configFile >> "CfgVehicles" >> _x) };
    if (_validBackpacks isEqualTo []) then { _validBackpacks = ["B_AssaultPack_dgtl"]; };

    private _validGoggles = _goggles select { isClass (configFile >> "CfgGlasses" >> _x) };

    private _validBinoculars = _binoculars select { isClass (configFile >> "CfgWeapons" >> _x) };
    if (_validBinoculars isEqualTo []) then { _validBinoculars = ["Binocular"]; };

    // 1. Attribution des conteneurs corporels et casque
    _unit forceAddUniform (selectRandom _validUniforms);
    _unit addVest (selectRandom _validVests);
    _unit addBackpack (selectRandom _validBackpacks);
    _unit addHeadgear (selectRandom _validHeadgears);

    if !(_validGoggles isEqualTo []) then {
        _unit addGoggles (selectRandom _validGoggles);
    };

    // 2. Télémètres / Jumelles et vision nocturne
    _unit addWeapon (selectRandom _validBinoculars);

    private _nvg = "NVGogglesB_blk_F";
    if (!isClass (configFile >> "CfgWeapons" >> _nvg)) then { _nvg = "NVGoggles_INDEP"; };
    _unit linkItem _nvg;

    // 3. Instruments de navigation et communication
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
    _unit linkItem "ItemWatch";
    _unit linkItem "ItemRadio";
    _unit linkItem "ItemGPS";

    // 4. Dotation Médicale de Survie
    for "_i" from 1 to 3 do { _unit addItemToUniform "FirstAidKit"; };

    // 5. Grenades offensives et fumigènes (INFO_EDITOR.md)
    private _fragGrenade = if (isClass (configFile >> "CfgMagazines" >> "CUP_HandGrenade_M67")) then { "CUP_HandGrenade_M67" } else { "HandGrenade" };
    for "_i" from 1 to 2 do { _unit addItemToVest _fragGrenade; };
    for "_i" from 1 to 2 do { _unit addItemToVest "SmokeShell"; };
    for "_i" from 1 to 2 do { _unit addItemToVest "SmokeShellGreen"; };

    // 6. Dotation en chargeurs pour armes conservées
    if (_primaryMag != "") then {
        for "_i" from 1 to 6 do { _unit addItemToVest _primaryMag; };
    };
    if (_handgunMag != "") then {
        for "_i" from 1 to 2 do { _unit addItemToVest _handgunMag; };
    };

    // 7. Restauration des accessoires d'armes
    { if (_x != "") then { _unit addPrimaryWeaponItem _x; }; } forEach _primaryItems;
    { if (_x != "") then { _unit addHandgunItem _x; }; } forEach _handgunItems;
    { if (_x != "") then { _unit addSecondaryWeaponItem _x; }; } forEach _secondaryItems;

    // 8. Maintien de l'arme principale en main
    _unit selectWeapon (primaryWeapon _unit);

    // 9. Patch Officiel RACS (CfgUnitInsignia)
    [_unit, "RACS_Badge"] call BIS_fnc_setUnitInsignia;

    true
};

// =============================================================================
// LOGIQUE DE TRAITEMENT
// =============================================================================

if (!isNull _targetUnit) then {
    // Traitement d'une unité individuelle
    [_targetUnit] call _fnc_equipSingleRACS;
} else {
    // 1. Traitement de toutes les unités indépendantes existantes (hors joueur)
    {
        private _isPilot = (_x isEqualTo player) 
            || {_x isEqualTo (missionNamespace getVariable ["player_0", objNull])} 
            || {isPlayer _x}
            || {(vehicleVarName _x) isEqualTo "player_0"} 
            || {(str _x) find "player_0" >= 0} 
            || {_x getVariable ["ORA_isPilot", false]};

        if (side (group _x) isEqualTo independent && {!_isPilot}) then {
            [_x] call _fnc_equipSingleRACS;
        };
    } forEach allUnits;

    // 2. Installation de l'écouteur événementiel pour les futures unités créées dynamiquement
    if (isNil "ORA_racsLoadoutEHAdded") then {
        ORA_racsLoadoutEHAdded = true;

        addMissionEventHandler ["EntityCreated", {
            params ["_entity"];

            if (_entity isKindOf "CAManBase") then {
                // Léger décalage pour s'assurer que le moteur a assigné le groupe et le camp
                _entity spawn {
                    params ["_unit"];
                    sleep 0.05;
                    if (isNull _unit || {!alive _unit}) exitWith {};

                    private _isPilot = (_unit isEqualTo player) 
                        || {_unit isEqualTo (missionNamespace getVariable ["player_0", objNull])} 
                        || {isPlayer _unit}
                        || {(vehicleVarName _unit) isEqualTo "player_0"} 
                        || {(str _unit) find "player_0" >= 0} 
                        || {_unit getVariable ["ORA_isPilot", false]};

                    if (side (group _unit) isEqualTo independent && {!_isPilot}) then {
                        [_unit] call ORA_fnc_applyRACSLoadout;
                    };
                };
            };
        }];
        diag_log "[ORA-LOADOUT] [OK] Écouteur EntityCreated pour les dotations RACS activé.";
    };
};

true

