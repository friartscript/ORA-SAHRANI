/*
    Auteur: ORA SQF Architect
    Description:
        Gère le panneau de lancement tactique ORA - Air Force (dialogue 7000).
        Configure les objectifs obligatoires, le choix exclusif du nombre de missions,
        les options de vol (téléguidage, alliés, pénalité éjection), la météo temps réel,
        l'aperçu caméra 3D de plane_0 et l'insertion directe du pilote dans le cockpit.
    Paramètres:
        0: _mode - Action à exécuter ("OPEN", "UPDATE_ENV_PREVIEW", "LAUNCH") [String]
        1: _args - Arguments contextuels optionnels [Array]
    Retour:
        [Boolean] - Résultat de l'opération
    Exemple:
        ["OPEN"] spawn ORA_fnc_mainMenu;
*/
params [
    ["_mode", "OPEN", [""]],
    ["_args", [], [[]]]
];

if (!hasInterface) exitWith { false };

// ============================================================================
// MODE : OUVERTURE DU DIALOGUE
// ============================================================================
if (_mode isEqualTo "OPEN") exitWith {
    private _plane = missionNamespace getVariable ["plane_0", objNull];

    // 1. Initialisation de la caméra 3D de prévisualisation de plane_0
    if (!isNull _plane) then {
        // Positionnement automatique cinématographique (3/4 avant surélevé)
        private _camPos = if (!isNil "post_camera" && {!isNull post_camera}) then {
            getPosATL post_camera
        } else {
            _plane modelToWorld [-11, 13, 2.4]
        };

        if (!isNil "MISSION_var_veh_cam" && {!isNull MISSION_var_veh_cam}) then {
            camDestroy MISSION_var_veh_cam;
        };

        MISSION_var_veh_cam = "camera" camCreate _camPos;
        MISSION_var_veh_cam camSetTarget _plane;
        MISSION_var_veh_cam camSetFov 0.65;
        MISSION_var_veh_cam camCommit 0;
        MISSION_var_veh_cam cameraEffect ["Internal", "Back", "rendertarget8"];
    };

    // 2. Création du dialogue
    private _created = createDialog "Refour_Main_Menu_Dialog";
    if (!_created) exitWith {
        diag_log "[ORA-UI] [ERREUR] Impossible de créer le dialogue Refour_Main_Menu_Dialog.";
        false
    };

    waitUntil { !isNull (findDisplay 7000) };
    private _display = findDisplay 7000;

    // 3. Objectifs Principaux (cochés d'office et verrouillés)
    {
        private _cb = _display displayCtrl _x;
        _cb cbSetChecked true;
        _cb ctrlEnable false;
    } forEach [7100, 7101, 7102, 7103];

    // 4. Choix du nombre de missions (EXCLUSIF : 1 seul choix actif)
    // 7110: 1 à 5 | 7111: 1 à 10 | 7112: 1 à 15 | 7113: 1 à 20
    private _countIDCs = [7110, 7111, 7112, 7113];
    
    // Par défaut : 1 à 5 missions sélectionné
    (_display displayCtrl 7110) cbSetChecked true;
    (_display displayCtrl 7111) cbSetChecked false;
    (_display displayCtrl 7112) cbSetChecked false;
    (_display displayCtrl 7113) cbSetChecked false;

    // Écouteur exclusif (comportement type bouton radio)
    {
        private _cb = _display displayCtrl _x;
        _cb ctrlAddEventHandler ["CheckedChanged", {
            params ["_ctrl", "_checked"];
            private _curIdc = ctrlIDC _ctrl;
            private _allCountIDCs = [7110, 7111, 7112, 7113];

            if (_checked isEqualTo 1) then {
                // Décocher tous les autres choix
                {
                    if (_x != _curIdc) then {
                        ((ctrlParent _ctrl) displayCtrl _x) cbSetChecked false;
                    };
                } forEach _allCountIDCs;
            } else {
                // Empêcher d'avoir 0 choix : maintenir au moins un choix coché
                private _anyChecked = _allCountIDCs findIf {
                    cbChecked ((ctrlParent _ctrl) displayCtrl _x)
                } != -1;

                if (!_anyChecked) then {
                    _ctrl cbSetChecked true;
                };
            };
        }];
    } forEach _countIDCs;

    // 5. Options Tactiques (cochables librement)
    // 7120: Téléguidage des tirs | 7121: Autres présences alliées
    (_display displayCtrl 7120) cbSetChecked false;
    (_display displayCtrl 7121) cbSetChecked true;

    // 6. Environnement & Météo
    private _currentHour = date select 3;
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
    } forEach [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];
    _ctrlTime lbSetCurSel _bestTimeIdx;

    private _ctrlClouds = _display displayCtrl 7201;
    lbClear _ctrlClouds;
    {
        private _idx = _ctrlClouds lbAdd format ["%1%%", _x];
        _ctrlClouds lbSetData [_idx, str (_x / 100)];
    } forEach [0, 15, 30, 50, 70, 85, 100];
    _ctrlClouds lbSetCurSel 1;

    private _ctrlFog = _display displayCtrl 7202;
    lbClear _ctrlFog;
    {
        private _idx = _ctrlFog lbAdd format ["%1%%", _x select 0];
        _ctrlFog lbSetData [_idx, str (_x select 1)];
    } forEach [[0, 0], [10, 0.05], [25, 0.15], [50, 0.35], [75, 0.60]];
    _ctrlFog lbSetCurSel 0;

    // 7. Initialisation de la Grande Carte Tactique
    private _mapCtrl = _display displayCtrl 7302;
    if (!isNull _mapCtrl) then {
        private _centerPos = if (!isNull _plane) then { getPosATL _plane } else { [10000, 10000, 0] };
        _mapCtrl ctrlMapAnimAdd [0, 0.22, _centerPos];
        ctrlMapAnimCommit _mapCtrl;
    };

    true
};

// ============================================================================
// MODE : MISE À JOUR VISUELLE EN TEMPS RÉEL DE LA MÉTÉO
// ============================================================================
if (_mode isEqualTo "UPDATE_ENV_PREVIEW") exitWith {
    private _display = findDisplay 7000;
    if (isNull _display) exitWith { false };

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

    0 setOvercast _overcast;
    0 setFog _fog;
    forceWeatherChange;
    simulWeatherSync;

    true
};

// ============================================================================
// MODE : LANCEMENT ET INSERTION DANS L'AVION
// ============================================================================
if (_mode isEqualTo "LAUNCH") exitWith {
    private _display = findDisplay 7000;
    if (isNull _display) exitWith { false };

    // Lecture du nombre de missions sélectionné (exclusif)
    private _missionCount = 5;
    if (cbChecked (_display displayCtrl 7111)) then { _missionCount = 10; };
    if (cbChecked (_display displayCtrl 7112)) then { _missionCount = 15; };
    if (cbChecked (_display displayCtrl 7113)) then { _missionCount = 20; };

    // Lecture des options tactiques
    private _optGuidance = cbChecked (_display displayCtrl 7120);
    private _optAllies   = cbChecked (_display displayCtrl 7121);

    // Enregistrement des paramètres dans l'état global de la mission
    missionNamespace setVariable ["ORA_setting_missionCount", _missionCount, true];
    missionNamespace setVariable ["ORA_setting_guidanceAssist", _optGuidance, true];
    missionNamespace setVariable ["ORA_setting_alliedPresence", _optAllies, true];

    diag_log format [
        "[ORA-LAUNCH] Missions: %1 | Guidage: %2 | Alliés: %3",
        _missionCount, _optGuidance, _optAllies
    ];

    // Fermeture du dialogue
    closeDialog 0;

    // Destruction propre de la caméra de prévisualisation
    if (!isNil "MISSION_var_veh_cam" && {!isNull MISSION_var_veh_cam}) then {
        MISSION_var_veh_cam cameraEffect ["Terminate", "Back"];
        camDestroy MISSION_var_veh_cam;
        MISSION_var_veh_cam = nil;
    };

    // Transition visuelle
    titleCut ["", "BLACK IN", 2];

    // INSERTION DIRECTE DANS L'AVION (plane_0)
    private _plane = missionNamespace getVariable ["plane_0", objNull];
    if (!isNull _plane && {alive _plane}) then {
        player moveInDriver _plane;
        _plane engineOn true;

        // Armement impératif de la surveillance de cockpit (Condition de défaite systématique)
        [player, _plane] call ORA_fnc_cockpitEgressForfeit;

        // Activation de l'aide au guidage d'armement selon le choix du joueur (IDC 7120)
        [_plane, _optGuidance] call ORA_fnc_weaponGuidance;
    } else {
        diag_log "[ORA-LAUNCH] [AVERTISSEMENT] plane_0 est introuvable pour l'insertion en cockpit.";
    };

    // Notification radio de début de mission
    [
        "ATC",
        format [localize "STR_ORA_RADIO_MISSION_LAUNCHED", _missionCount]
    ] call ORA_fnc_radioMsg;

    // Démarrage automatique de la campagne de sorties opérationnelles
    [_missionCount] spawn {
        params ["_count"];
        sleep 8;
        ["RANDOM", _count] spawn ORA_fnc_taskLaunch;
    };

    true
};

false

