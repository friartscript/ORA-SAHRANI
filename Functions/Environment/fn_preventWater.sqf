/*
    Auteur: ORA SQF Architect
    Description:
        Surveille et sécurise les unités d'infanterie au sol pour empêcher
        les fantassins à pied de se noyer, de nager ou de rester bloqués dans l'eau
        lors des déplacements tactiques sur les rives de Sahrani.

        STRICTEMENT RÉSERVÉ AUX UNITÉS D'INFANTERIE AU SOL À PIED (INFANTRY ONLY) :
        - Exclut formellement tous les équipages à bord de véhicules terrestres.
        - Exclut formellement tous les équipages de bateaux et navires en mer (aucun impact sur la marine).
        - Exclut formellement les pilotes d'avions et d'hélicoptères ainsi que le joueur.
        - Exclut les plongeurs militaires habilités au milieu aquatique.
        - Si un fantassin à pied commence à nager ou s'enfonce dans l'eau, il est extrait
          en douceur vers la rive ferme la plus proche et son itinéraire de groupe est recalibré.

    Paramètres:
        Aucun

    Retour:
        [Boolean] - true si le service de prévention est actif

    Exemple:
        [] spawn ORA_fnc_preventWater;
*/

if (!isServer) exitWith { false };

// Empêcher l'exécution de boucles multiples en parallèle
if (missionNamespace getVariable ["ORA_preventWaterRunning", false]) exitWith { false };
missionNamespace setVariable ["ORA_preventWaterRunning", true];

diag_log "[ORA-ENVIRONMENT] [OK] Démarrage du contrôleur anti-noyade pour l'infanterie au sol.";

while {true} do {
    sleep 3;

    // FILTRE STRICT : Unités d'infanterie à pied uniquement (aucune unité embarquée dans un bateau ou véhicule)
    private _trackedInfantry = allUnits select {
        alive _x 
        && {_x isKindOf "CAManBase"} 
        && {isNull (objectParent _x)} 
        && {!isPlayer _x} 
        && {!(_x isEqualTo player)} 
        && {!(_x getVariable ["ORA_isPilot", false])} 
        && {!(_x isKindOf "B_diver_F")} 
        && {!(_x isKindOf "O_diver_F")} 
        && {!(_x isKindOf "I_diver_F")}
    };

    {
        private _unit = _x;
        private _anim = animationState _unit;
        private _isSwimming = (_anim find "swm" != -1) || (_anim find "swim" != -1);
        private _posWorld = getPosWorld _unit;
        private _inDeepWater = surfaceIsWater _posWorld && { underwater _unit || {(_posWorld select 2) < -0.5} };

        // Détection d'un fantassin à pied tombé à l'eau
        if (_isSwimming || _inDeepWater) then {
            private _currentPos = getPosATL _unit;
            private _safePos = [_currentPos, 10, 80, 2, 0, 0.3, 0] call BIS_fnc_findSafePos;

            // Repositionnement sécurisé sur la terre ferme
            if (!surfaceIsWater _safePos && {!(_safePos isEqualTo [0, 0, 0])}) then {
                _unit switchMove "";
                _unit setPosATL [_safePos select 0, _safePos select 1, 0.1];
                _unit setVelocity [0, 0, 0];

                private _grp = group _unit;
                if (!isNull _grp) then {
                    _unit doMove _safePos;

                    // Si le waypoint de l'escouade est placé en mer, le réajuster sur terre
                    private _curWP = [_grp, currentWaypoint _grp];
                    if (surfaceIsWater (waypointPosition _curWP)) then {
                        deleteWaypoint _curWP;
                        private _newWp = _grp addWaypoint [_safePos, 0];
                        _newWp setWaypointType "MOVE";
                        _newWp setWaypointSpeed "NORMAL";
                        _newWp setWaypointBehaviour "AWARE";
                        _grp setCurrentWaypoint _newWp;
                    };
                };

                diag_log format ["[ORA-WATER] [EXTRACTION] Fantassin %1 extrait de l'eau vers la terre ferme à %2", typeOf _unit, _safePos];
            };
        };
    } forEach _trackedInfantry;
};

true
