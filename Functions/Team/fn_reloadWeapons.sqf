params [["_units", [], [[]]]];

if !(missionNamespace getVariable ["MISSION_intro_finished", false]) then {
    waitUntil { sleep 0.5; missionNamespace getVariable ["MISSION_intro_finished", false] };
};

sleep 1.2;

if (_units isEqualTo []) then {
    private _squad = [];
    for "_i" from 0 to 5 do {
        private _u = missionNamespace getVariable [format ["player_%1", _i], objNull];
        if (isNull _u) then { _u = missionNamespace getVariable [format ["player_0%1", _i], objNull]; };
        if (!isNull _u) then { _squad pushBackUnique _u; };
    };
    if (!isNull player) then {
        {
            if (alive _x && { side _x == side player || group _x == group player }) then {
                _squad pushBackUnique _x;
            };
        } forEach (units (group player) + playableUnits + switchableUnits);
    };
    _units = _squad select { alive _x && { count (weapons _x) > 0 } };
};

{
    private _unit = _x;
    if (alive _unit) then {
        if (backpack _unit == "") then {
            private _bp = if (secondaryWeapon _unit != "") then { "B_Kitbag_cbr" } else { "B_Kitbag_cbr" };
            _unit addBackpack _bp;
        };

        private _pWeapon = primaryWeapon _unit;
        if (_pWeapon != "") then {
            private _muzzles = getArray (configFile >> "CfgWeapons" >> _pWeapon >> "muzzles");
            if (_muzzles isEqualTo []) then { _muzzles = ["this"]; };

            {
                private _muzzle = _x;
                private _compat = if (_muzzle == "this") then {
                    compatibleMagazines _pWeapon
                } else {
                    compatibleMagazines [_pWeapon, _muzzle]
                };

                if (count _compat > 0) then {
                    private _chosen = "";
                    private _loaded = primaryWeaponMagazine _unit;
                    private _loadedForMuzzle = _loaded select { _x in _compat };

                    if (count _loadedForMuzzle > 0) then {
                        _chosen = _loadedForMuzzle select 0;
                    } else {
                        private _inv = (magazines _unit) select { _x in _compat };
                        if (count _inv > 0) then {
                            _chosen = _inv select 0;
                        } else {
                            _chosen = _compat select 0;
                        };
                    };

                    if (_chosen != "") then {
                        if (_loadedForMuzzle isEqualTo []) then {
                            _unit addWeaponItem [_pWeapon, _chosen, true];
                        };

                        private _magCap = getNumber (configFile >> "CfgMagazines" >> _chosen >> "count");
                        private _target = if (_muzzle != "this") then { 6 } else { if (_magCap >= 100) then { 3 } else { 8 } };
                        private _current = { _x in _compat } count (magazines _unit);
                        private _needed = (_target - _current) max 0;

                        for "_i" from 1 to _needed do {
                            if (_unit canAdd _chosen) then {
                                _unit addMagazine _chosen;
                            } else {
                                if (_unit canAddItemToBackpack _chosen) then {
                                    _unit addItemToBackpack _chosen;
                                };
                            };
                        };
                    };
                };
            } forEach _muzzles;
        };

        private _hWeapon = handgunWeapon _unit;
        if (_hWeapon != "") then {
            private _compatH = compatibleMagazines _hWeapon;
            if (count _compatH > 0) then {
                private _chosenH = "";
                private _loadedH = handgunMagazine _unit;
                if (count _loadedH > 0) then {
                    _chosenH = _loadedH select 0;
                } else {
                    private _invH = (magazines _unit) select { _x in _compatH };
                    if (count _invH > 0) then {
                        _chosenH = _invH select 0;
                    } else {
                        _chosenH = _compatH select 0;
                    };
                };

                if (_chosenH != "") then {
                    if (_loadedH isEqualTo []) then {
                        _unit addWeaponItem [_hWeapon, _chosenH, true];
                    };

                    private _currentH = { _x in _compatH } count (magazines _unit);
                    private _neededH = (3 - _currentH) max 0;

                    for "_i" from 1 to _neededH do {
                        if (_unit canAdd _chosenH) then {
                            _unit addMagazine _chosenH;
                        } else {
                            if (_unit canAddItemToBackpack _chosenH) then {
                                _unit addItemToBackpack _chosenH;
                            };
                        };
                    };
                };
            };
        };

        private _sWeapon = secondaryWeapon _unit;
        if (_sWeapon != "") then {
            private _compatS = compatibleMagazines _sWeapon;
            if (count _compatS > 0) then {
                private _chosenS = "";
                private _loadedS = secondaryWeaponMagazine _unit;
                if (count _loadedS > 0) then {
                    _chosenS = _loadedS select 0;
                } else {
                    private _invS = (magazines _unit) select { _x in _compatS };
                    if (count _invS > 0) then {
                        _chosenS = _invS select 0;
                    } else {
                        _chosenS = _compatS select 0;
                    };
                };

                if (_chosenS != "") then {
                    if (_loadedS isEqualTo []) then {
                        _unit addWeaponItem [_sWeapon, _chosenS, true];
                    };

                    if (backpack _unit == "") then {
                        _unit addBackpack "B_Kitbag_cbr";
                    };

                    private _currentS = { _x in _compatS } count (magazines _unit);
                    private _neededS = (3 - _currentS) max 0;

                    for "_i" from 1 to _neededS do {
                        if (_unit canAddItemToBackpack _chosenS) then {
                            _unit addItemToBackpack _chosenS;
                        } else {
                            if (_unit canAdd _chosenS) then {
                                _unit addMagazine _chosenS;
                            };
                        };
                    };
                };
            };
        };
    };
} forEach _units;

{
    private _unit = _x;
    if (alive _unit && { vehicle _unit == _unit }) then {
        private _pw = primaryWeapon _unit;
        if (_pw != "" && { count (primaryWeaponMagazine _unit) > 0 }) then {
            _unit selectWeapon _pw;
        } else {
            private _hw = handgunWeapon _unit;
            if (_hw != "" && { count (handgunMagazine _unit) > 0 }) then {
                _unit selectWeapon _hw;
            };
        };
    };
} forEach _units;
