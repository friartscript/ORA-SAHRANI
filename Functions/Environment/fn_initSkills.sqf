/*
    Auteur: ORA SQF Architect
    Description:
        Configure les compétences de tir, de détection et le moral des unités
        (alliés RACS et menaces hostiles) sans boucle infinie sur le scheduler.
    Paramètres:
        0: _unit - Unité optionnelle à configurer individuellement [Object]
    Retour:
        [Boolean] - true si appliqué
    Exemple:
        [] call ORA_fnc_initSkills;
*/
params [
    ["_targetUnit", objNull, [objNull]]
];

private _fnc_applyUnitSkill = {
    params ["_unit"];
    if (!alive _unit) exitWith {};

    private _side = side _unit;

    if (_side isEqualTo independent) then {
        // Forces alliées RACS
        _unit enableFatigue false;
        _unit enableStamina false;
        _unit setUnitTrait ["loadCoef", 0.1];
        _unit setAnimSpeedCoef 1.1;

        _unit setSkill ["aimingAccuracy", 0.75 + random 0.15];
        _unit setSkill ["aimingShake",    0.80 + random 0.15];
        _unit setSkill ["aimingSpeed",    0.80 + random 0.15];
        _unit setSkill ["spotDistance",   0.90 + random 0.10];
        _unit setSkill ["spotTime",       0.90 + random 0.10];
        _unit setSkill ["commanding",     1.00];
        _unit setSkill ["courage",        1.00];
        _unit setSkill ["general",        0.90];
        _unit allowFleeing 0;
    } else {
        // Forces hostiles
        _unit setSkill ["aimingAccuracy", 0.25 + random 0.20];
        _unit setSkill ["aimingShake",    0.25 + random 0.20];
        _unit setSkill ["aimingSpeed",    0.30 + random 0.20];
        _unit setSkill ["spotDistance",   0.40 + random 0.20];
        _unit setSkill ["spotTime",       0.35 + random 0.20];
        _unit setSkill ["courage",        0.90];
        _unit setSkill ["general",        0.50];
    };
};

if (!isNull _targetUnit) then {
    [_targetUnit] call _fnc_applyUnitSkill;
} else {
    {
        [_x] call _fnc_applyUnitSkill;
    } forEach allUnits;

    // Écouteur pour appliquer automatiquement aux futures unités créées dynamiquement
    if (isNil "ORA_skillsEventHandlerAdded") then {
        ORA_skillsEventHandlerAdded = true;
        addMissionEventHandler ["EntityCreated", {
            params ["_entity"];
            if (_entity isKindOf "CAManBase") then {
                [_entity] call ORA_fnc_initSkills;
            };
        }];
    };
};

true
