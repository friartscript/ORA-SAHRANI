if (!isServer) exitWith {};

[] spawn {
    private _OPEN_DIST      = 4.5;
    private _OPEN_DIST_SQR  = _OPEN_DIST * _OPEN_DIST;
    private _CLOSE_DIST     = 6.0;
    private _CLOSE_DIST_SQR = _CLOSE_DIST * _CLOSE_DIST;
    private _MIN_OPEN_TIME  = 4.0;
    private _COOLDOWN       = 1.5;
    private _CHECK_FREQ     = 0.4;

    private _fnc_getBuildingDoors = {
        params ["_bldg"];

        private _cached = _bldg getVariable ["LL_doorData", nil];
        if (!isNil "_cached") exitWith { _cached };

        private _allAnimNames = animationNames _bldg;
        private _doorList = [];
        private _registeredAnims = [];

        {
            private _animName = _x;
            private _low = toLowerANSI _animName;

            private _isCandidate = (
                (_low find "door" != -1) || 
                (_low find "gate" != -1) || 
                (_low find "garage" != -1) || 
                (_low find "shutter" != -1) || 
                (_low find "hatch" != -1) || 
                (_low find "barrier" != -1) || 
                (_low find "vrata" != -1)
            );

            private _isExcluded = (
                (_low find "handle" != -1) || 
                (_low find "sound" != -1) || 
                (_low find "lock" != -1) || 
                (_low find "switch" != -1) || 
                (_low find "knob" != -1) || 
                (_low find "bolt" != -1) || 
                (_low find "hinge" != -1) || 
                (_low find "bell" != -1) || 
                (_low find "light" != -1) || 
                (_low find "key" != -1)
            );

            if (_isCandidate && !_isExcluded && !(_animName in _registeredAnims)) then {
                _registeredAnims pushBack _animName;

                private _doorNum = 1;
                private _digits = [];
                {
                    if (_x in ["0","1","2","3","4","5","6","7","8","9"]) then {
                        _digits pushBack _x;
                    };
                } forEach (_low splitString "");
                if (count _digits > 0) then {
                    _doorNum = parseNumber (_digits joinString "");
                };

                private _doorPos = [0, 0, 0];
                private _candidates = [
                    _animName,
                    format ["%1_trigger", _animName],
                    format ["%1_axis", _animName],
                    format ["%1_sound", _animName],
                    format ["%1_handle", _animName],
                    format ["Door_%1_trigger", _doorNum],
                    format ["door_%1_trigger", _doorNum],
                    format ["Door_%1", _doorNum],
                    format ["door_%1", _doorNum],
                    format ["Gate_%1", _doorNum],
                    format ["gate_%1", _doorNum],
                    format ["Garage_%1", _doorNum],
                    format ["garage_%1", _doorNum]
                ];

                {
                    private _posM = _bldg selectionPosition _x;
                    if (_posM isNotEqualTo [0, 0, 0]) exitWith {
                        _doorPos = _bldg modelToWorld _posM;
                    };
                } forEach _candidates;

                if (_doorPos isEqualTo [0, 0, 0]) then {
                    _doorPos = getPosATL _bldg;
                };

                private _initOpen = (_bldg animationPhase _animName) > 0.5;
                _doorList pushBack [_doorNum, _animName, _doorPos, _initOpen, 0, 0, false];
            };
        } forEach _allAnimNames;

        _bldg setVariable ["LL_doorData", _doorList];
        _doorList
    };

    while {true} do {
        sleep _CHECK_FREQ;

        private _allActiveUnits = allUnits select { alive _x && vehicle _x == _x };
        private _aiUnits = _allActiveUnits select { !isPlayer _x };

        if (_aiUnits isEqualTo []) then { continue; };

        private _nearBuildings = [];
        {
            private _pos = getPosATL _x;
            {
                _nearBuildings pushBackUnique _x;
            } forEach (nearestObjects [_pos, ["House", "Building"], 15]);
        } forEach _aiUnits;

        private _currentTime = time;

        {
            private _bldg = _x;
            private _doors = [_bldg] call _fnc_getBuildingDoors;

            if (_doors isNotEqualTo []) then {
                {
                    _x params [
                        "_doorNum",
                        "_anim",
                        "_doorPos",
                        "_isOpen",
                        "_lastActionTime",
                        "_openedAt",
                        "_openedByAI"
                    ];

                    private _currentPhase = _bldg animationPhase _anim;
                    if (!_isOpen && _currentPhase > 0.6) then {
                        _isOpen = true;
                        _x set [3, true];
                    };
                    if (_isOpen && _currentPhase < 0.1) then {
                        _isOpen = false;
                        _openedByAI = false;
                        _x set [3, false];
                        _x set [6, false];
                    };

                    private _aiNear = _aiUnits findIf { (_x distanceSqr _doorPos) < _OPEN_DIST_SQR } != -1;

                    if (_aiNear) then {
                        if (!_isOpen) then {
                            private _lockVal = _bldg getVariable [format ["bis_disabled_Door_%1", _doorNum], 0];
                            private _locked = (_lockVal isEqualTo 1) || (_lockVal isEqualTo true);

                            if (!_locked && { _currentTime - _lastActionTime >= _COOLDOWN }) then {
                                _bldg animateSource [_anim, 1, false];
                                _bldg animateSource [format ["%1_sound", _anim], 1];
                                _bldg animateSource [format ["%1_source", _anim], 1, false];
                                _bldg animateDoor [_anim, 1, false];
                                _bldg animateDoor [format ["%1_source", _anim], 1, false];
                                _bldg animateDoor [format ["Door_%1_source", _doorNum], 1, false];
                                _bldg animateDoor [format ["Door_%1", _doorNum], 1, false];
                                _bldg animate [_anim, 1];

                                playSound3D ["A3\Sounds_F\environment\doors\DoorWoodSingleOpen_1.wss", objNull, false, _doorPos, 0.45, 1.0, 15];

                                _x set [3, true];
                                _x set [4, _currentTime];
                                _x set [5, _currentTime];
                                _x set [6, true];
                            };
                        } else {
                            _x set [5, _currentTime];
                        };
                    } else {
                        if (_isOpen && _openedByAI) then {
                            if (_currentTime - _openedAt >= _MIN_OPEN_TIME && { _currentTime - _lastActionTime >= _COOLDOWN }) then {
                                private _anyoneClose = _allActiveUnits findIf { (_x distanceSqr _doorPos) < _CLOSE_DIST_SQR } != -1;

                                if (!_anyoneClose) then {
                                    _bldg animateSource [_anim, 0, false];
                                    _bldg animateSource [format ["%1_sound", _anim], 0];
                                    _bldg animateSource [format ["%1_source", _anim], 0, false];
                                    _bldg animateDoor [_anim, 0, false];
                                    _bldg animateDoor [format ["%1_source", _anim], 0, false];
                                    _bldg animateDoor [format ["Door_%1_source", _doorNum], 0, false];
                                    _bldg animateDoor [format ["Door_%1", _doorNum], 0, false];
                                    _bldg animate [_anim, 0];

                                    playSound3D ["A3\Sounds_F\environment\doors\DoorWoodSingleClose_1.wss", objNull, false, _doorPos, 0.45, 1.0, 15];

                                    _x set [3, false];
                                    _x set [4, _currentTime];
                                    _x set [6, false];
                                };
                            };
                        };
                    };
                } forEach _doors;
            };
        } forEach _nearBuildings;
    };
};
