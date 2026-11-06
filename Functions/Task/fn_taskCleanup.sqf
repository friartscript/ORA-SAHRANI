/*
    Auteur: ORA SQF Architect
    Description:
        Fonction de nettoyage automatique et optimisée des entités générées par une tâche.
        Conforme aux spécifications :
        - Dès qu'une tâche est terminée, toutes les unités (au sol, mer ou air) et véhicules créés
          pour cette tâche disparaissent immédiatement s'ils sont à plus de 2000m du joueur.
        - Si des entités sont encore à 2000m ou moins du joueur à la complétion, elles sont conservées
          temporairement pour éviter tout pop visuel immersif indésirable, puis supprimées dès que
          le joueur s'éloigne au-delà de 2000m.
        - Supprime les véhicules, les équipages, les troupes d'infanterie au sol, les épaves et cadavres.
        - Supprime proprement les groupes vides associés pour préserver les quotas de groupes du moteur Arma 3.
        - Protection absolue du joueur, de son appareil (plane_0) et du ravitailleur C-130J.

    Paramètres:
        0: _rawEntities   - Liste d'objets, véhicules ou sous-tableaux d'entités [Array]
        1: _rawGroups     - Groupes créés pour la tâche à supprimer une fois vidés [Array, défaut: []]
        2: _minDistance   - Distance seuil en mètres [Scalar, défaut: 2000]
        3: _checkInterval - Intervalle de vérification en secondes [Scalar, défaut: 4]

    Retour:
        [Script Handle]

    Exemple:
        [_taskEntities, [_enemyVehGroup, _alliedGroup], 2000] spawn ORA_fnc_taskCleanup;
*/

params [
    ["_rawEntities", [], [[]]],
    ["_rawGroups", [], [[], 0]],
    ["_minDistance", 2000, [0]],
    ["_checkInterval", 4, [0]]
];

// Gestion de surcharge : [_rawEntities, 2000]
if (_rawGroups isEqualType 0) then {
    _minDistance = _rawGroups;
    _rawGroups = [];
};

// Protéger le joueur, son aéronef et les éléments permanents du scénario
private _protected = [
    player,
    vehicle player,
    missionNamespace getVariable ["plane_0", objNull],
    missionNamespace getVariable ["tanker_c130", objNull]
];

private _objectsToClean = [];
private _groupsToClean = [];

// Fonction récursive d'extraction des objets et groupes
private _fnc_collect = {
    params ["_item"];
    if (isNil "_item") exitWith {};

    if (_item isEqualType []) exitWith {
        { [_x] call _fnc_collect; } forEach _item;
    };

    if (_item isEqualType grpNull) exitWith {
        if (!isNull _item) then {
            _groupsToClean pushBackUnique _item;
            {
                if (!isNull _x && {!(_x in _protected)}) then {
                    _objectsToClean pushBackUnique _x;
                };
            } forEach (units _item);
        };
    };

    if (_item isEqualType objNull) exitWith {
        if (!isNull _item && {!(_item in _protected)}) then {
            _objectsToClean pushBackUnique _item;
            // Inclure l'équipage actuel ou survivant
            {
                if (!isNull _x && {!(_x in _protected)}) then {
                    _objectsToClean pushBackUnique _x;
                };
            } forEach (crew _item);
        };
    };
};

[_rawEntities] call _fnc_collect;
[_rawGroups] call _fnc_collect;

// Lancement du thread asynchrone de nettoyage
[_objectsToClean, _groupsToClean, _minDistance, _checkInterval, _protected] spawn {
    params ["_objects", "_groups", "_minDist", "_interval", "_protectedList"];

    // 1. Passe initiale immédiate : suppression directe des entités > _minDist
    private _playerObj = vehicle player;
    if (isNull _playerObj) then { _playerObj = player; };

    private _remaining = [];

    {
        private _ent = _x;
        if (!isNull _ent && {!(_ent in _protectedList)}) then {
            private _dist = _playerObj distance _ent;
            if (_dist > _minDist) then {
                deleteVehicle _ent;
            } else {
                _remaining pushBack _ent;
            };
        };
    } forEach _objects;

    // 2. Si aucune entité ne reste dans la zone des 2000m, suppression directe des groupes
    if (_remaining isEqualTo []) exitWith {
        {
            if (!isNull _x) then {
                while {count (waypoints _x) > 0} do {
                    deleteWaypoint ((waypoints _x) select 0);
                };
                if ((units _x) isEqualTo []) then {
                    deleteGroup _x;
                };
            };
        } forEach _groups;
    };

    // 3. Surveillance continue des entités restantes (utilisation d'un forEach sécurisé)
    while { _remaining isNotEqualTo [] } do {
        sleep _interval;

        _playerObj = vehicle player;
        if (isNull _playerObj) then { _playerObj = player; };

        private _stillAlive = [];

        {
            private _ent = _x;
            if (!isNull _ent && {!(_ent in _protectedList)}) then {
                private _dist = _playerObj distance _ent;
                if (_dist > _minDist) then {
                    deleteVehicle _ent;
                } else {
                    _stillAlive pushBack _ent;
                };
            };
        } forEach _remaining;

        _remaining = _stillAlive;
    };

    // 4. Suppression des groupes orphelins devenus vides
    {
        if (!isNull _x) then {
            while {count (waypoints _x) > 0} do {
                deleteWaypoint ((waypoints _x) select 0);
            };
            if ((units _x) isEqualTo []) then {
                deleteGroup _x;
            };
        };
    } forEach _groups;
};
