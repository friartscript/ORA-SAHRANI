/*
    Auteur: ORA SQF Architect
    Description:
        Génère les entrées du journal de bord (Briefing natif Arma 3) pour player_0
        détaillant l'opération de défense du territoire de Sahrani contre l'invasion de l'AAF.
    Paramètres:
        Aucun
    Retour:
        [Boolean] - true si créé avec succès
    Exemple:
        [] call ORA_fnc_setupBriefing;
*/
if (!hasInterface) exitWith { false };

// V. SIGNAUX & TRANSMISSIONS
player createDiaryRecord [
    "diary",
    [
        localize "STR_ORA_Briefing_Signal_Title",
        localize "STR_ORA_Briefing_Signal_Text"
    ]
];

// IV. RÈGLES D'ENGAGEMENT & SÉCURITÉ
player createDiaryRecord [
    "diary",
    [
        localize "STR_ORA_Briefing_ROE_Title",
        localize "STR_ORA_Briefing_ROE_Text"
    ]
];

// III. EXÉCUTION
player createDiaryRecord [
    "diary",
    [
        localize "STR_ORA_Briefing_Execution_Title",
        localize "STR_ORA_Briefing_Execution_Text"
    ]
];

// II. MISSION & OBJECTIFS
player createDiaryRecord [
    "diary",
    [
        localize "STR_ORA_Briefing_Mission_Title",
        localize "STR_ORA_Briefing_Mission_Text"
    ]
];

// I. SITUATION (OPORD - INVASION AAF DE SAHRANI)
player createDiaryRecord [
    "diary",
    [
        localize "STR_LL_Briefing_Title",
        localize "STR_LL_Briefing_Text"
    ]
];

true
