# 🛠️ Méthode d'Intégration et de Traduction (Stringtable)

## 1. Règles Générales de Langue

- **Langue Principale :** L'**Anglais** est la langue principale de référence de la mission.
- **Balises `<Original>` et `<English>` :** Doivent impérativement être rédigées en anglais.
- **Traduction Multi-Langues Obligatoire :** Tous les textes du jeu doivent être traduits dans l'ensemble des langues supportées par Arma 3.

---

## 2. Méthode d'Intégration Non Destructive

Les textes de la mission sont compilés par un script Python (`compile_stringtable.py`). Il ne faut **pas** modifier manuellement `stringtable.xml` sous peine de voir les modifications écrasées lors de la prochaine génération.

La méthode propre consiste à ajouter les définitions dans l'un des fichiers XML sources à côté du script SQF correspondant (par exemple `fn_addDroneAction.sqf` → `fn_addDroneAction.xml`), puis à régénérer la stringtable globale.

---

## 3. Procédure Pas à Pas

1. Créez ou modifiez le fichier XML à côté de votre script SQF (ex: `fn_addDroneAction.xml`).
2. Ajoutez vos clés de traduction en incluant toutes les langues d'Arma 3 :

```xml
<?xml version="1.0" encoding="utf-8"?>
<Keys>
    <Key ID="STR_Drone_Surveillance">
        <Original>[DRONE] Surveillance</Original>
        <English>[DRONE] Surveillance</English>
        <French>[DRONE] Surveillance</French>
        <Spanish>[DRON] Vigilancia</Spanish>
        <German>[DROHNE] Überwachung</German>
        <Italian>[DRONE] Sorveglianza</Italian>
        <Polish>[DRON] Inwigilacja</Polish>
        <Portuguese>[DRONE] Vigilância</Portuguese>
        <Russian>[БПЛА] Наблюдение</Russian>
        <Czech>[DRON] Sledování</Czech>
        <Korean>[드론] 감시</Korean>
        <Japanese>[ドローン] 監視</Japanese>
        <Chinese>[無人機] 監視</Chinese>
        <Chinesesimp>[无人机] 监视</Chinesesimp>
        <Turkish>[İHA] Gözetleme</Turkish>
    </Key>
</Keys>
```

3. Dans votre fichier SQF, utilisez la clé localisée : `localize "STR_Drone_Surveillance"`.
4. Exécutez le script `compile_stringtable.py` pour régénérer le fichier `stringtable.xml` global.

---

## 4. Exemple d'Intégration du Briefing Militaire (Onglet Natif & Contexte Tactique)

Pour le briefing natif du journal de bord (`createDiaryRecord ["diary", ...]`), les clés sont configurées dans `Functions/Player/fn_setupBriefing.xml` :
- `STR_LL_Briefing_Title` / `STR_LL_Briefing_Text` : I. Situation tactique — Invasion de Sahrani par les forces de l'AAF (Ordre d'opération OPORD, consigne d'analyse des données de mission).
- `STR_ORA_Briefing_Mission_Title` / `STR_ORA_Briefing_Mission_Text` : II. Mission & Objectifs (Protection des forces RACS, destruction des forces d'invasion AAF, préservation de plane_0, interdiction d'éjection).
- `STR_ORA_Briefing_Execution_Title` / `STR_ORA_Briefing_Execution_Text` : III. Exécution (Check-list piste, autorisation tour, guidage AWACS, engagement de cibles AAF, RTB).
- `STR_ORA_Briefing_ROE_Title` / `STR_ORA_Briefing_ROE_Text` : IV. Règles d'engagement & Sécurité (PID obligatoire, menaces Cheetah/Titan, intégrité cockpit).
- `STR_ORA_Briefing_Signal_Title` / `STR_ORA_Briefing_Signal_Text` : V. Signaux & Transmissions (Tour Sahrani, AWACS Magic-1, canal de détresse 243.0 MHz).

Pour l'onglet d'analyse tactique (`createDiaryRecord ["Context", ...]`), les clés sont configurées dans `Functions/Briefing/fn_initContext.xml` :
- `STR_ORA_CONTEXT_TAB` : Intitulé de l'onglet « Contexte Tactique ».
- `STR_ORA_CONTEXT_THEATER_TITLE` / `STR_ORA_CONTEXT_THEATER_TEXT` : 1. Campagne de défense du territoire de Sahrani contre l'invasion de l'AAF.
- `STR_ORA_CONTEXT_THREAT_TITLE` / `STR_ORA_CONTEXT_THREAT_TEXT` : 2. Ordre de bataille de l'AAF (chasseurs A-143 Buzzard, blindés Kuma/Mora, DCA Cheetah/Titan).
- `STR_ORA_CONTEXT_ALLIES_TITLE` / `STR_ORA_CONTEXT_ALLIES_TEXT` : 3. Forces souveraines du Royal Army Corps of Sahrani (RACS) et escadre ORA.

