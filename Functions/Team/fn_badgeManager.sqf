/*
 * LL_fnc_badgeManager
 *
 * Description:
 *   Applique l'insigne RACS_Badge à l'unité spécifiée.
 *
 * Arguments:
 *   0: <OBJECT> L'unité à qui appliquer le badge
 */

params [
    ["_unit", objNull, [objNull]]
];

if (isNull _unit) exitWith {};

[_unit, "RACS_Badge"] call BIS_fnc_setUnitInsignia;
