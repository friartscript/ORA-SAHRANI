/*
    Auteur: ORA SQF Architect
    Description:
        Initialise le contexte géopolitique, l'ordre de bataille adverse (AAF)
        et la situation défensive du Royaume de Sahrani dans le journal de bord ("Context").
    Paramètres:
        Aucun
    Retour:
        [Boolean] - true si initialisé
    Exemple:
        [] call ORA_fnc_initContext;
*/
if (!hasInterface) exitWith { false };

if (!(player diarySubjectExists "Context")) then {
    player createDiarySubject ["Context", localize "STR_ORA_CONTEXT_TAB"];

    // 3. FORCES DU ROYAUME (RACS)
    player createDiaryRecord [
        "Context",
        [
            localize "STR_ORA_CONTEXT_ALLIES_TITLE",
            localize "STR_ORA_CONTEXT_ALLIES_TEXT"
        ]
    ];

    // 2. FORCES D'INVASION AAF & RÉSEAU MENACES
    player createDiaryRecord [
        "Context",
        [
            localize "STR_ORA_CONTEXT_THREAT_TITLE",
            localize "STR_ORA_CONTEXT_THREAT_TEXT"
        ]
    ];

    // 1. CAMPAGNE DE DÉFENSE DE SAHRANI
    player createDiaryRecord [
        "Context",
        [
            localize "STR_ORA_CONTEXT_THEATER_TITLE",
            localize "STR_ORA_CONTEXT_THEATER_TEXT"
        ]
    ];
};

true
