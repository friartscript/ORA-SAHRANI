/*
    Auteur: ORA SQF Architect
    Description:
        Support Radio 0-8-1 : Appel du Ravitailleur C-130J Rodeo-1.
        Le ravitailleur quitte son orbite d'attente à 2000m et converge vers
        l'aéronef du joueur pour un ravitaillement complet (carburant, intégrité, missiles).

        Sécurité anti-collision totale :
        - disableCollisionWith entre le ravitailleur et l'avion du joueur.
        - Approche étagée sécurisée (+40m au-dessus du joueur).
        - Avertissements successifs à 1 km puis à 500 m ordonnant de maintenir le cap ("ne pas bouger").
        - Ravitaillement effectif à <= 200 m (100% fuel, réparations, missiles).
        - Reprise automatique de l'orbite d'attente une fois l'opération terminée.
    Paramètres:
        Aucun
    Retour:
        [Boolean] - true si l'appel a été pris en compte
    Exemple:
        [] spawn ORA_fnc_callTanker;
*/

if (!hasInterface) exitWith { false };

private _playerVeh = vehicle player;

// 1. Vérification que le joueur est bien aux commandes d'un appareil en vol
if (_playerVeh == player || {!(_playerVeh isKindOf "Air")}) exitWith {
    [
        localize "STR_ORA_TANKER_CALLSIGN",
        localize "STR_ORA_TANKER_MUST_BE_AIRBORNE",
        "STR_ORA_TANKER_MUST_BE_AIRBORNE"
    ] call ORA_fnc_radioMsg;
    false
};

// 2. Récupération de l'instance active du ravitailleur C-130J
private _tanker = missionNamespace getVariable ["ORA_tankerC130", objNull];
if (isNull _tanker || {!alive _tanker}) then {
    _tanker = [] call ORA_fnc_airRefuel;
    sleep 1;
};

if (isNull _tanker || {!alive _tanker}) exitWith { false };

// 3. Empêcher les requêtes multiples en simultané
if (_tanker getVariable ["ORA_tankerInbound", false]) exitWith {
    [
        localize "STR_ORA_TANKER_CALLSIGN",
        localize "STR_ORA_TANKER_BUSY_MSG",
        "STR_ORA_TANKER_BUSY_MSG"
    ] call ORA_fnc_radioMsg;
    false
};

_tanker setVariable ["ORA_tankerInbound", true, true];

// 4. Transmission radio d'acquittement et prise en charge du vecteur
[
    localize "STR_ORA_TANKER_CALLSIGN",
    localize "STR_ORA_TANKER_INBOUND_MSG",
    "STR_ORA_TANKER_INBOUND_MSG"
] call ORA_fnc_radioMsg;

// 5. Sécurité anti-collision matérielle absolue
_tanker disableCollisionWith _playerVeh;
_playerVeh disableCollisionWith _tanker;

// 6. Navigation active d'interception et surveillance de distance
[_tanker, _playerVeh] spawn {
    params ["_tanker", "_playerVeh"];

    private _grp = group (driver _tanker);
    private _warned1km = false;
    private _warned500m = false;
    private _contactReached = false;
    private _startTime = time;
    private _timeout = 360; // 6 minutes max

    // Libération des waypoints d'orbite pour foncer vers le joueur
    while {count waypoints _grp > 0} do { deleteWaypoint [_grp, 0]; };

    private _wp = _grp addWaypoint [getPos _playerVeh, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "NORMAL";
    _wp setWaypointBehaviour "CARELESS";
    _wp setWaypointCombatMode "BLUE";

    while {alive _tanker && {alive _playerVeh} && {vehicle player == _playerVeh} && {!_contactReached} && {(time - _startTime) < _timeout}} do {
        private _dist = _tanker distance _playerVeh;
        private _playerAlt = ((getPosATL _playerVeh) select 2) max 450; // Plafond sécurisé vis-à-vis du relief

        // Étage sécurisé : l'avion ravitailleur vole 40 mètres au-dessus du joueur
        _tanker flyInHeight (_playerAlt + 40);

        // Avertissement à 1 km : ordonner au pilote de ne pas bouger
        if (_dist <= 1000 && {!_warned1km}) then {
            _warned1km = true;
            [
                localize "STR_ORA_TANKER_CALLSIGN",
                localize "STR_ORA_TANKER_WARN_1KM",
                "STR_ORA_TANKER_WARN_1KM"
            ] call ORA_fnc_radioMsg;
            titleText [
                format ["<t color='#ffcc00' size='1.15'>[%1] %2</t>", localize "STR_ORA_TANKER_CALLSIGN", localize "STR_ORA_TANKER_WARN_1KM"],
                "PLAIN DOWN",
                0.4,
                true,
                true
            ];
        };

        // Avertissement à 500 m : contact imminent, interdiction de manœuvrer
        if (_dist <= 500 && {!_warned500m}) then {
            _warned500m = true;
            [
                localize "STR_ORA_TANKER_CALLSIGN",
                localize "STR_ORA_TANKER_WARN_500M",
                "STR_ORA_TANKER_WARN_500M"
            ] call ORA_fnc_radioMsg;
            titleText [
                format ["<t color='#00e5ff' size='1.2'>[%1] %2</t>", localize "STR_ORA_TANKER_CALLSIGN", localize "STR_ORA_TANKER_WARN_500M"],
                "PLAIN DOWN",
                0.4,
                true,
                true
            ];
        };

        // Zone de ravitaillement atteinte (<= 200m)
        if (_dist <= 200) exitWith {
            _contactReached = true;
        };

        // Guidage dynamique continu vers le vecteur anticipé du joueur
        private _vel = velocity _playerVeh;
        private _targetPos = (getPos _playerVeh) vectorAdd (_vel vectorMultiply 3);
        _tanker doMove _targetPos;
        _wp setWaypointPosition [_targetPos, 0];

        sleep 1;
    };

    // 7. Ravitaillement effectif (géré en parallèle par fn_airRefuel.sqf à <= 200m)
    if (_contactReached) then {
        // Maintien de l'accompagnement pendant 8 secondes pour finaliser le transfert
        sleep 8;
        [
            localize "STR_ORA_TANKER_CALLSIGN",
            localize "STR_ORA_TANKER_DISENGAGE",
            "STR_ORA_TANKER_DISENGAGE"
        ] call ORA_fnc_radioMsg;
    };

    // 8. Retour sécurisé en orbite de croisière (LOITER) à 2000m
    _tanker setVariable ["ORA_tankerInbound", false, true];

    while {count waypoints _grp > 0} do { deleteWaypoint [_grp, 0]; };

    private _orbitCenter = [10000, 10000, 2000];
    private _wpLoiter = _grp addWaypoint [_orbitCenter, 0];
    _wpLoiter setWaypointType "LOITER";
    _wpLoiter setWaypointLoiterType "CIRCLE";
    _wpLoiter setWaypointLoiterRadius 3200;
    _wpLoiter setWaypointLoiterAltitude 2000;
    _wpLoiter setWaypointSpeed "LIMITED";
    _wpLoiter setWaypointBehaviour "CARELESS";
    _wpLoiter setWaypointCombatMode "BLUE";
    _tanker flyInHeight 2000;

};

true

