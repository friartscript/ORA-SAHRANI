/*
    Auteur: ORA SQF Architect
    Description:
        Applique un chargement modulaire à l'unité spécifiée en respectant
        le profil de pilote de l'air de la mission ORA.
    Paramètres:
        0: _unit - Unité ciblée [Object]
    Retour:
        [Boolean] - true si appliqué
    Exemple:
        [player] call ORA_fnc_applyLoadout;
*/
params [
    ["_unit", player, [objNull]]
];

if (isNull _unit || {!alive _unit} || {!local _unit}) exitWith { false };

// Appel de la dotation pilote standardisée
[_unit] call ORA_fnc_initLoadout;

true
