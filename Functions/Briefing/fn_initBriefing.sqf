/*
    Auteur: ORA SQF Architect
    Description:
        Initialise le manuel opérationnel de vol et de combat aérien dans
        le journal de bord Arma 3 (createDiaryRecord / createDiarySubject).
    Paramètres:
        Aucun
    Retour:
        [Boolean] - true si initialisé
    Exemple:
        [] call ORA_fnc_initBriefing;
*/
if (!hasInterface) exitWith { false };

if (!(player diarySubjectExists "FlightManual")) then {
    player createDiarySubject ["FlightManual", localize "STR_ORA_MANUAL_TAB"];

    player createDiaryRecord [
        "FlightManual",
        [
            localize "STR_ORA_MANUAL_EMERGENCY_TITLE",
            localize "STR_ORA_MANUAL_EMERGENCY_TEXT"
        ]
    ];

    player createDiaryRecord [
        "FlightManual",
        [
            localize "STR_ORA_MANUAL_GFORCE_TITLE",
            localize "STR_ORA_MANUAL_GFORCE_TEXT"
        ]
    ];

    player createDiaryRecord [
        "FlightManual",
        [
            localize "STR_ORA_MANUAL_WEAPONS_TITLE",
            localize "STR_ORA_MANUAL_WEAPONS_TEXT"
        ]
    ];

    player createDiaryRecord [
        "FlightManual",
        [
            localize "STR_ORA_MANUAL_AVIONICS_TITLE",
            localize "STR_ORA_MANUAL_AVIONICS_TEXT"
        ]
    ];
};

true
