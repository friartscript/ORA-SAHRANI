params [["_mode", ""], ["_args", []]];

if (isNil "MISSION_var_current_task_index") then { MISSION_var_current_task_index = 1; };

if (_mode == "OPEN") exitWith {
    if (!isNil "post_camera" && {!isNull post_camera}) then {
        MISSION_var_veh_cam = "camera" camCreate (getPosATL post_camera);
        if (!isNil "vehicles_spawner" && {!isNull vehicles_spawner}) then {
            MISSION_var_veh_cam camSetTarget vehicles_spawner;
        } else {
            MISSION_var_veh_cam setVectorDirAndUp [vectorDir post_camera, vectorUp post_camera];
        };
        MISSION_var_veh_cam camCommit 0;
        MISSION_var_veh_cam cameraEffect ["Internal", "Back", "rendertarget8"];
    };

    private _dialogCreated = createDialog "Refour_Main_Menu_Dialog";

    if (!_dialogCreated) exitWith {
        titleCut ["", "BLACK IN", 1];
    };

    waitUntil { !isNull (findDisplay 7000) };
    private _display = findDisplay 7000;
    
    // --- Tâches Obligatoires (cochées et bloquées) ---
    private _cbMan1 = _display displayCtrl 7100;
    _cbMan1 cbSetChecked true;
    _cbMan1 ctrlEnable false;

    private _cbMan2 = _display displayCtrl 7101;
    _cbMan2 cbSetChecked true;
    _cbMan2 ctrlEnable false;

    private _cbMan3 = _display displayCtrl 7102;
    _cbMan3 cbSetChecked true;
    _cbMan3 ctrlEnable false;

    // --- Tâches Optionnelles (décochées) ---
    for "_i" from 7110 to 7118 do {
        private _cbOpt = _display displayCtrl _i;
        if (!isNull _cbOpt) then {
            _cbOpt cbSetChecked false;
            _cbOpt ctrlAddEventHandler ["CheckedChanged", {
                ["CHECK_LIMIT"] call LL_fnc_spawn_main_menu;
            }];
        };
    };

    private _cbRebel = _display displayCtrl 7120;
    if (!isNull _cbRebel) then {
        _cbRebel cbSetChecked false;
    };

    private _currentHour = date select 3;
    private _currentOvercast = overcast;
    private _currentFog = fog;

    private _ctrlTime = _display displayCtrl 7200;
    lbClear _ctrlTime;
    private _bestTimeIdx = 0;
    private _minTimeDiff = 999;
    {
        private _strTime = if (_x < 10) then { format ["0%1:00", _x] } else { format ["%1:00", _x] };
        private _idx = _ctrlTime lbAdd _strTime;
        _ctrlTime lbSetData [_idx, str _x];
        private _diff = abs (_x - _currentHour);
        if (_diff < _minTimeDiff) then {
            _minTimeDiff = _diff;
            _bestTimeIdx = _idx;
        };
    } forEach [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
    _ctrlTime lbSetCurSel _bestTimeIdx;

    private _ctrlClouds = _display displayCtrl 7201;
    lbClear _ctrlClouds;
    private _bestCloudsIdx = 0;
    private _minCloudsDiff = 999;
    {
        private _idx = _ctrlClouds lbAdd format ["%1%%", _x];
        _ctrlClouds lbSetData [_idx, str (_x / 100)];
        private _diff = abs ((_x / 100) - _currentOvercast);
        if (_diff < _minCloudsDiff) then {
            _minCloudsDiff = _diff;
            _bestCloudsIdx = _idx;
        };
    } forEach [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    _ctrlClouds lbSetCurSel _bestCloudsIdx;

    private _ctrlFog = _display displayCtrl 7202;
    lbClear _ctrlFog;
    private _bestFogIdx = 0;
    private _minFogDiff = 999;
    {
        private _idx = _ctrlFog lbAdd format ["%1%%", _x select 0];
        _ctrlFog lbSetData [_idx, str (_x select 1)];
        private _diff = abs ((_x select 1) - _currentFog);
        if (_diff < _minFogDiff) then {
            _minFogDiff = _diff;
            _bestFogIdx = _idx;
        };
    } forEach [[0, 0], [10, 0.1], [20, 0.2], [30, 0.3], [40, 0.4], [50, 0.5], [60, 0.6], [70, 0.7], [80, 0.8], [90, 0.9], [100, 1.0]];
    _ctrlFog lbSetCurSel _bestFogIdx;

    private _vehCtrl = _display displayCtrl 7204;
    lbClear _vehCtrl;
    
    private _allCarConfigs = "(
        isClass _x && 
        { (getNumber (_x >> 'scope')) == 2 } && 
        { (configName _x) isKindOf 'Car' } && 
        { !((configName _x) isKindOf 'Wheeled_APC_F') } && 
        { !((configName _x) isKindOf 'Tank') } && 
        { !((configName _x) isKindOf 'Air') } && 
        { !((configName _x) isKindOf 'Ship') } && 
        { (getNumber (_x >> 'armor')) <= 150 } && 
        { (getText (_x >> 'vehicleClass')) in ['Car', 'Cars', 'CUP_Vehicles_Vehicles'] || (getText (_x >> 'editorSubcategory')) in ['EdSubcat_Cars', 'EdSubcat_Civilian_Cars'] } && 
        { getNumber (_x >> 'side') in [0, 1, 2, 3] }
    )" configClasses (configFile >> "CfgVehicles");

    private _vehiclesList = [];
    {
        private _cls = configName _x;
        private _dName = getText (_x >> "displayName");
        if (_dName != "") then {
            _vehiclesList pushBack [_cls, _dName];
        };
    } forEach _allCarConfigs;

    _vehiclesList sort true;
    
    if (count _vehiclesList == 0) then {
        _vehiclesList = [
            ["CUP_I_LR_MG_RACS", "Land Rover (Armé)"],
            ["CUP_C_SUV_CIV", "SUV Civil"],
            ["CUP_C_Offroad_Striped", "Offroad"],
            ["CUP_C_Datsun", "Pickup Datsun"]
        ];
    };

    private _defaultVehIdx = 0;
    {
        _x params ["_class", "_name"];
        private _idx = _vehCtrl lbAdd format ["%1 (%2)", _name, _class];
        _vehCtrl lbSetData [_idx, _class];
        if (_class == "CUP_I_LR_Transport_RACS") then {
            _defaultVehIdx = _idx;
        };
    } forEach _vehiclesList;
    _vehCtrl lbSetCurSel _defaultVehIdx;
    ['SELECT_VEHICLE', [_vehCtrl, _defaultVehIdx]] spawn LL_fnc_spawn_main_menu;

    private _locCtrl = _display displayCtrl 7300;
    lbClear _locCtrl;
    
    private _allSectorMarkers = allMapMarkers select {
        (_x select [0, 7]) == "marker_"
    };
    
    if (count _allSectorMarkers == 0) then {
        _allSectorMarkers = ["marker_0", "marker_1"];
    };
    
    {
        private _markerName = _x;
        private _mPos = getMarkerPos _markerName;
        private _gridStr = mapGridPosition _mPos;
        private _formattedGrid = if (count _gridStr >= 6) then {
            format ["%1-%2", _gridStr select [0, 3], _gridStr select [3, 3]]
        } else {
            _gridStr
        };
        private _displayName = format [localize "STR_FORMAT_SECTOR_GRID", _forEachIndex + 1, _formattedGrid];
        private _idx = _locCtrl lbAdd _displayName;
        _locCtrl lbSetData [_idx, _markerName];
    } forEach _allSectorMarkers;
    
    if (count _allSectorMarkers > 0) then {
        private _randomLocIdx = floor (random (count _allSectorMarkers));
        _locCtrl lbSetCurSel _randomLocIdx;
    };

    private _insCtrl = _display displayCtrl 7301;
    lbClear _insCtrl;
    private _i1 = _insCtrl lbAdd (localize "STR_INS_HELI");
    _insCtrl lbSetData [_i1, "HELI"];
    private _i2 = _insCtrl lbAdd (localize "STR_INS_AIRDROP");
    _insCtrl lbSetData [_i2, "TAP"];
    _insCtrl lbSetCurSel 0;

    uiSleep 0.05;
    ["UPDATE_MAP"] call LL_fnc_spawn_main_menu;
};

if (_mode == "SELECT_VEHICLE") exitWith {
    _args params ["_ctrl", "_selIndex"];
    private _vehClass = _ctrl lbData _selIndex;
    if (_vehClass == "") exitWith {};
    
    if (isNil "MISSION_var_spawning_veh") then { MISSION_var_spawning_veh = false; };
    if (MISSION_var_spawning_veh) exitWith {};
    MISSION_var_spawning_veh = true;
    
    MISSION_var_selected_vehicle_class = _vehClass;
    
    if (!isNil "vehicles_spawner" && {!isNull vehicles_spawner}) then {
        if (!isNil "MISSION_var_preview_veh" && {!isNull MISSION_var_preview_veh}) then {
            deleteVehicle MISSION_var_preview_veh;
            MISSION_var_preview_veh = objNull;
        };
        
        private _oldVehs = nearestObjects [getPosATL vehicles_spawner, ["AllVehicles", "Thing"], 30];
        {
            if (_x != player && {!(_x isKindOf "Man")}) then {
                deleteVehicle _x;
            };
        } forEach _oldVehs;
        
        uiSleep 0.1;
        
        private _spawnPos = getPosATL vehicles_spawner;
        _spawnPos set [2, (_spawnPos select 2) + 0.1];
        
        MISSION_var_preview_veh = createVehicle [_vehClass, _spawnPos, [], 0, "CAN_COLLIDE"];
        MISSION_var_preview_veh setPosATL _spawnPos;
        MISSION_var_preview_veh setDir (getDir vehicles_spawner);
        MISSION_var_preview_veh allowDamage false;
        MISSION_var_preview_veh enableSimulation false;
        
        if (!isNil "MISSION_var_veh_cam" && {!isNull MISSION_var_veh_cam}) then {
            MISSION_var_veh_cam camSetTarget MISSION_var_preview_veh;
            MISSION_var_veh_cam camCommit 0;
        };
    };
    
    MISSION_var_spawning_veh = false;
};



if (_mode == "UPDATE_MAP") exitWith {
    private _display = findDisplay 7000;
    if (isNull _display) exitWith {};
    private _locCtrl = _display displayCtrl 7300;
    private _mapCtrl = _display displayCtrl 7302;
    if (isNull _mapCtrl) exitWith {};
    
    private _selectedLocMarker = _locCtrl lbData (lbCurSel _locCtrl);
    private _pos = getPosATL player;
    
    if (_selectedLocMarker != "") then {
        private _mPos = getMarkerPos _selectedLocMarker;
        if ((_mPos select 0) != 0 || (_mPos select 1) != 0) then {
            _pos = _mPos;
        };
    };
    
    _mapCtrl ctrlMapAnimAdd [0, 0.08, _pos];
    ctrlMapAnimCommit _mapCtrl;
};

if (_mode == "UPDATE_ENV_PREVIEW") exitWith {
    uiSleep 1;
    private _display = findDisplay 7000;
    if (isNull _display) exitWith {};
    
    private _ctrlTime = _display displayCtrl 7200;
    private _ctrlClouds = _display displayCtrl 7201;
    private _ctrlFog = _display displayCtrl 7202;
    
    private _hour = parseNumber (_ctrlTime lbData (lbCurSel _ctrlTime));
    private _overcast = parseNumber (_ctrlClouds lbData (lbCurSel _ctrlClouds));
    private _fog = parseNumber (_ctrlFog lbData (lbCurSel _ctrlFog));
    
    private _date = date;
    _date set [3, _hour];
    _date set [4, 0];
    setDate _date;
    1 setOvercast _overcast;
    1 setFog _fog;
    forceWeatherChange;
    simulWeatherSync;
};

if (_mode == "CHECK_LIMIT") exitWith {
    private _display = findDisplay 7000;
    if (isNull _display) exitWith {};

    private _selectedCount = 0;
    private _taskIDCs = [7110, 7111, 7113, 7114, 7116, 7117];

    {
        private _cb = _display displayCtrl _x;
        if (cbChecked _cb) then {
            _selectedCount = _selectedCount + 1;
        };
    } forEach _taskIDCs;

    if (_selectedCount >= 3) then {
        {
            private _cb = _display displayCtrl _x;
            if (!cbChecked _cb) then {
                _cb ctrlEnable false;
            };
        } forEach _taskIDCs;
    } else {
        {
            private _cb = _display displayCtrl _x;
            _cb ctrlEnable true;
        } forEach _taskIDCs;
    };
};

if (_mode == "LAUNCH") exitWith {
    private _display = findDisplay 7000;
    
    private _selectedTasks = [];
    private _taskMap = [
        [7110, "TASK_CAPTIVE"],
        [7111, "TASK_HVT"],
        [7113, "TASK_TRANSMISSION"],
        [7114, "TASK_CHEMICAL"],
        [7116, "TASK_DOCUMENTS"],
        [7117, "TASK_TIGRIS"]
    ];
    
    {
        _x params ["_idc", "_taskId"];
        private _cb = _display displayCtrl _idc;
        if (cbChecked _cb) then {
            _selectedTasks pushBack _taskId;
        };
    } forEach _taskMap;
    
    if (count _selectedTasks == 0) exitWith {
        hint localize "STR_ERR_NO_TASK";
    };
    
    private _ctrlTime = _display displayCtrl 7200;
    private _ctrlClouds = _display displayCtrl 7201;
    private _ctrlFog = _display displayCtrl 7202;
    private _locCtrl = _display displayCtrl 7300;
    private _insCtrl = _display displayCtrl 7301;
    
    private _hour = parseNumber (_ctrlTime lbData (lbCurSel _ctrlTime));
    private _overcast = parseNumber (_ctrlClouds lbData (lbCurSel _ctrlClouds));
    private _fog = parseNumber (_ctrlFog lbData (lbCurSel _ctrlFog));
    private _selectedLocationMarker = _locCtrl lbData (lbCurSel _locCtrl);
    private _selectedInsertion = _insCtrl lbData (lbCurSel _insCtrl);
    private _rebelAmbushEnabled = cbChecked (_display displayCtrl 7120);
    
    closeDialog 0;
    
    if (!isNil "MISSION_var_preview_veh" && {!isNull MISSION_var_preview_veh}) then {
        deleteVehicle MISSION_var_preview_veh;
        MISSION_var_preview_veh = nil;
    };
    
    if (!isNil "vehicles_spawner" && {!isNull vehicles_spawner}) then {
        private _oldVehs = nearestObjects [getPosATL vehicles_spawner, ["AllVehicles", "Thing"], 30];
        {
            if (_x != player && {!(_x isKindOf "Man")}) then {
                deleteVehicle _x;
            };
        } forEach _oldVehs;
        deleteVehicle vehicles_spawner;
        vehicles_spawner = nil;
    };

    if (!isNil "post_camera" && {!isNull post_camera}) then {
        deleteVehicle post_camera;
        post_camera = nil;
    };

    {
        private _lampObj = missionNamespace getVariable [_x, objNull];
        if (!isNull _lampObj) then {
            deleteVehicle _lampObj;
            missionNamespace setVariable [_x, nil];
        };
    } forEach ["post_lamp_0", "post_lamp_1", "post_lamp_2"];
    
    if (!isNil "MISSION_var_veh_cam" && {!isNull MISSION_var_veh_cam}) then {
        MISSION_var_veh_cam cameraEffect ["Terminate", "Back"];
        camDestroy MISSION_var_veh_cam;
        MISSION_var_veh_cam = nil;
    };
    
    private _date = date;
    _date set [3, _hour];
    _date set [4, 0];
    setDate _date;
    0 setOvercast _overcast;
    0 setFog _fog;
    forceWeatherChange;
    simulWeatherSync;
    
    private _targetPos = getMarkerPos _selectedLocationMarker;
    missionNamespace setVariable ["MISSION_var_targetPos", _targetPos];
    
    private _allMarkers = allMapMarkers select { (_x select [0, 7]) == "marker_" };
    {
        if (_x == _selectedLocationMarker) then {
            _x setMarkerAlpha 1;
        } else {
            _x setMarkerAlpha 0;
        };
    } forEach _allMarkers;

    // Trouver une LZ (un autre marker) à au moins 900m de l'objectif, le plus proche possible de cette limite
    private _validLzMarkers = _allMarkers select { (getMarkerPos _x) distance2D _targetPos >= 900 };
    private _lzMarker = "";
    
    if (count _validLzMarkers > 0) then {
        _lzMarker = [_validLzMarkers, _targetPos] call BIS_fnc_nearestPosition;
    } else {
        // Fallback: Aucun marker à + de 900m, on prend le plus éloigné disponible
        private _otherMarkers = _allMarkers - [_selectedLocationMarker];
        if (count _otherMarkers > 0) then {
            private _furthest = _otherMarkers select 0;
            private _maxDist = 0;
            {
                private _dist = (getMarkerPos _x) distance2D _targetPos;
                if (_dist > _maxDist) then { _maxDist = _dist; _furthest = _x; };
            } forEach _otherMarkers;
            _lzMarker = _furthest;
        } else {
            _lzMarker = _selectedLocationMarker; // Fallback absolu si 1 seul marker
        };
    };

    private _dropPosCenter = getMarkerPos _lzMarker;

    private _selectedVehClass = if (!isNil "MISSION_var_selected_vehicle_class") then { MISSION_var_selected_vehicle_class } else { "CUP_I_LR_Transport_RACS" };

    switch (_selectedInsertion) do {
        case "HELI": {
            [_selectedLocationMarker, _dropPosCenter, _selectedVehClass] spawn LL_fnc_intro_01;
        };
        case "TAP": {
            [_selectedLocationMarker, _dropPosCenter, _selectedVehClass] spawn LL_fnc_intro_02;
        };
        default {
            [_selectedLocationMarker, _dropPosCenter, _selectedVehClass] spawn LL_fnc_intro_01;
        };
    };

    [_dropPosCenter, 400, 15, _targetPos] spawn LL_fnc_ambientCivilians;
    [_targetPos, 400, 30, _dropPosCenter] spawn LL_fnc_ambientCivilians;

    [_dropPosCenter] spawn LL_fnc_ambientSheep;
    [_targetPos] spawn LL_fnc_ambientSheep;

    if (_rebelAmbushEnabled) then {
        [_dropPosCenter, _targetPos] spawn LL_fnc_rebelAmbush;
    };

    // Lancement du gestionnaire dynamique des tâches
    [_selectedLocationMarker, _selectedInsertion, _selectedTasks] spawn LL_fnc_task_generator;

    // Les fondus au noir et réouvertures sont gérés exclusivement par fn_intro_01 / fn_intro_02
};
