/*
    Auteur: ORA SQF Architect
    Description:
        Gère l'avion ravitailleur C-130J en vol perpétuel au-dessus de Sahrani.
        Caractéristiques :
        - Toujours visible sur la carte (marqueur temps réel avec cap et altitude).
        - Totalement invisible et invincible pour les ennemis (allowDamage false, setCaptive true).
        - Effectue une orbite (loiter) stable à 2000m d'altitude.
        - Ravitaillement automatique en vol : dès que l'avion du joueur s'approche
          à moins de 200m du C-130J, il récupère son carburant, sa santé et l'intégralité
          de ses munitions et missiles à 100%.
    Paramètres:
        0: _orbitCenter - Centre de l'orbite de vol [Array, défaut: [10000, 10000, 2000]]
        1: _altitude    - Altitude de vol en mètres [Scalar, défaut: 2000]
        2: _radius      - Rayon de l'orbite en mètres [Scalar, défaut: 3200]
    Retour:
        [Object] - L'aéronef C-130J ravitailleur
    Exemple:
        [] spawn ORA_fnc_airRefuel;
*/

params [
    ["_orbitCenter", [10000, 10000, 2000], [[]]],
    ["_altitude", 2000, [0]],
    ["_radius", 3200, [0]]
];

if (!hasInterface && !isServer) exitWith { objNull };

// Éviter la duplication si le ravitailleur existe déjà
private _existingTanker = missionNamespace getVariable ["ORA_tankerC130", objNull];
if (!isNull _existingTanker && {alive _existingTanker}) exitWith { _existingTanker };

// 1. Détermination de la classe d'avion (C-130J RACS prioritaire)
private _c130Class = "CUP_I_C130J_RACS";
if (!isClass (configFile >> "CfgVehicles" >> _c130Class)) then {
    if (isClass (configFile >> "CfgVehicles" >> "CUP_B_C130J_USMC")) then {
        _c130Class = "CUP_B_C130J_USMC";
    } else {
        if (isClass (configFile >> "CfgVehicles" >> "B_T_VTOL_01_infantry_F")) then {
            _c130Class = "B_T_VTOL_01_infantry_F";
        } else {
            _c130Class = "I_Plane_Fighter_03_CAS_F";
        };
    };
};

// 2. Positionnement initial et création en vol (FLY)
private _spawnPos = _orbitCenter getPos [_radius, 0];
_spawnPos set [2, _altitude];

private _tanker = createVehicle [_c130Class, _spawnPos, [], 0, "FLY"];
_tanker setPosASL _spawnPos;
_tanker setDir 90;
_tanker setVelocityModelSpace [0, 85, 0]; // Vitesse de croisière stable (~300 km/h)
_tanker flyInHeight _altitude;

// 3. Configuration de l'invincibilité et de l'invisibilité vis-à-vis des ennemis
_tanker allowDamage false;
_tanker setDamage 0;
_tanker setFuel 1;
_tanker setCaptive true; // Rendu 100% invisible / neutre pour l'IA ennemie (jamais ciblé)
_tanker setVehicleRadar 0; // Radar passif uniquement

// Sécurité anti-collision avec le vecteur aérien du joueur
private _playerPlaneInit = missionNamespace getVariable ["plane_0", objNull];
if (!isNull _playerPlaneInit) then {
    _tanker disableCollisionWith _playerPlaneInit;
    _playerPlaneInit disableCollisionWith _tanker;
};

// Création de l'équipage RACS allié
createVehicleCrew _tanker;
private _tankerGroup = group (driver _tanker);
_tankerGroup enableAttack false;

{
    _x allowDamage false;
    _x setDamage 0;
    _x setCaptive true;
    _x disableAI "AUTOCOMBAT";
    _x disableAI "TARGET";
    _x disableAI "AUTOTARGET";
} forEach (crew _tanker);

// 4. Trajectoire de vol en orbite (LOITER) perpétuelle et stable
private _wp = _tankerGroup addWaypoint [_orbitCenter, 0];
_wp setWaypointType "LOITER";
_wp setWaypointLoiterType "CIRCLE";
_wp setWaypointLoiterRadius _radius;
_wp setWaypointLoiterAltitude _altitude;
_wp setWaypointSpeed "LIMITED";
_wp setWaypointBehaviour "CARELESS";
_wp setWaypointCombatMode "BLUE";

missionNamespace setVariable ["ORA_tankerC130", _tanker, true];

// 5. Création du marqueur de carte permanent
private _markerName = "mrk_c130_tanker";
deleteMarkerLocal _markerName;
createMarkerLocal [_markerName, getPos _tanker];
_markerName setMarkerTypeLocal "b_air";
_markerName setMarkerColorLocal "ColorBlue";
_markerName setMarkerTextLocal (format [" %1", localize "STR_ORA_TANKER_MARKER"]);

// 6. Boucle de surveillance, mise à jour du marqueur et ravitaillement automatique
[_tanker, _markerName] spawn {
    params ["_tanker", "_markerName"];

    private _lastRefuelTime = -999;
    private _lastProximityNoticeTime = -999;

    while { alive _tanker } do {
        // Maintien du carburant infini du ravitailleur pour vol perpétuel
        if (fuel _tanker < 0.5) then {
            _tanker setFuel 1;
        };

        // Mise à jour de la position et de l'orientation du marqueur sur la carte
        _markerName setMarkerPosLocal (getPos _tanker);
        _markerName setMarkerDirLocal (getDir _tanker);

        // Détection de l'appareil du joueur
        private _playerVeh = vehicle player;

        if (alive player && {_playerVeh != player} && {_playerVeh isKindOf "Air"}) then {
            _tanker disableCollisionWith _playerVeh;
            _playerVeh disableCollisionWith _tanker;
            private _dist = _playerVeh distance _tanker;

            // Indication de proximité à l'approche (entre 200m et 1200m)
            if (_dist > 200 && {_dist < 1200} && {(time - _lastProximityNoticeTime) > 20}) then {
                _lastProximityNoticeTime = time;
                private _msg = format [localize "STR_ORA_TANKER_APPROACH", round _dist];
                titleText [format ["<t color='#55ccff' size='0.95'>[RAVITAILLEUR] %1</t>", _msg], "PLAIN DOWN", 0.35, true, true];
            };

            // RAVITAILLEMENT EFFECTIF À MOINS DE 200 MÈTRES
            if (_dist <= 200) then {
                // 1. Essence à 100%
                _playerVeh setFuel 1;

                // 2. Santé à 100% (Appareil et Pilote)
                _playerVeh setDamage 0;
                player setDamage 0;

                // 3. Munitions et Missiles à 100%
                _playerVeh setVehicleAmmo 1;
                _playerVeh setVehicleAmmoDef 1;

                // Recharge complète de l'ensemble des pylônes d'armement dynamiques
                private _pylons = getPylonMagazines _playerVeh;
                if (_pylons isNotEqualTo []) then {
                    {
                        private _magClass = _x;
                        private _maxCount = getNumber (configFile >> "CfgMagazines" >> _magClass >> "count");
                        if (_maxCount <= 0) then { _maxCount = 1; };
                        _playerVeh setAmmoOnPylon [_forEachIndex + 1, _maxCount];
                    } forEach _pylons;
                };

                // Notification visuelle et sonore (avec anti-spam de 12 secondes)
                if ((time - _lastRefuelTime) > 12) then {
                    _lastRefuelTime = time;

                    // Son de confirmation radio
                    playSoundUI ["ORA_Radio_Click", 1.2, 1];

                    // Transmission radio de confirmation du ravitailleur
                    [
                        localize "STR_ORA_TANKER_CALLSIGN",
                        localize "STR_ORA_TANKER_SUCCESS_MSG",
                        ""
                    ] call ORA_fnc_radioMsg;

                    // Message HUD en vert vif à l'écran
                    titleText [
                        format ["<t color='#00ff88' size='1.15'>%1</t>", localize "STR_ORA_TANKER_REPLENISHED"],
                        "PLAIN DOWN",
                        0.5,
                        true,
                        true
                    ];

                };
            };
        };

        sleep 0.5;
    };

    deleteMarkerLocal _markerName;
};

_tanker
