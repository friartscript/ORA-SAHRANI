# TASK_RULES.md — Règles de codage des missions (SINGLE-PLAYER)

Ce document est la référence obligatoire pour tout développement de tâche dans cette mission.
Il s'adresse à un agent IA ou développeur qui doit coder une nouvelle tâche, une interaction PNJ ou un scénario.

> **RAPPEL CRUCIAL : MISSION SOLO UNIQUEMENT**
> Cette mission est exclusivement **Single-Player**. Tout s'exécute localement sur la machine du joueur. 
> Il n'y a **aucun** trafic réseau, pas de séparation Serveur/Client, et **aucune commande multijoueur** (`remoteExec`, `publicVariable`, vérifications `isServer` ou `hasInterface`) ne doit être utilisée.

---

## 1. Architecture des fichiers

```
tasks/
  fn_taskXX.sqf            ← Logique complète de la tâche (spawn, scénarios, états, actions)
  taskXX_tasks.xml         ← Titres, descriptions et marqueurs de tâche (STR_LL_Task_XX_*)
  taskXX_dialogues.xml     ← Dialogues PNJ et narrateur (STR_LL_Task_XX_S*)
  taskXX_briefing.xml      ← Briefing de la tâche (STR_LL_Diary_*)
```

- Chaque tâche a son propre ensemble de fichiers XML dans `tasks/`.
- Toute modification des textes se fait dans `tasks/*.xml`, jamais dans `stringtable.xml` directement.
- Après modification XML, régénérer avec : `python compile_stringtable.py`
- Toujours enregistrer les fichiers XML en **UTF-8 sans BOM**.

*(Note : Plus besoin de fichier `_addAction.sqf` séparé pour le client, tout peut être centralisé dans le même fichier puisque le code s'exécute localement).*

---

## 2. Règles de spawn des PNJ

### Anti-Glitch (Spawn, Murs & Pathfinding) : Z + 0.2, CAN_COLLIDE, Groupes Séparés & Pathfinding Découplé

Pour garantir que les IA ne traversent pas les murs, ne s'enfoncent pas dans le sol et ne se rentrent pas les unes dans les autres :

1. **Élévation au spawn (Z + 0.2) :** Tout PNJ ambiant ou de tâche spawné dans ou près d'un bâtiment doit être positionné à `Z + 0.2` (ex: `_pos set [2, (_pos select 2) + 0.2]`). Ne pas modifier cette hauteur au-delà de +0.2 pour éviter que les unités ne réapparaissent sur les toits.
2. **Placement CAN_COLLIDE :** Toujours utiliser `"CAN_COLLIDE"` dans `createUnit` pour imposer le placement initial.
3. **Groupes Individuels (Ambiance) :** Chaque PNJ ambiant doit être créé dans son propre groupe (`createGroup [civilian, true]`). Si plusieurs PNJ ambiants partagent le même groupe, la logique d'escouade les forcera à rejoindre le leader en ligne droite à travers les murs.
4. **Pathfinding & Déplacement Intérieur / Extérieur (Découplé) :**
   - **Civils d'intérieur (`INDOOR`) :** Une IA apparue à l'intérieur d'un bâtiment ne doit **JAMAIS** recevoir un ordre `doMove` direct vers une position d'un autre bâtiment distant. Ses déplacements se font exclusivement entre les `buildingPos` du **MÊME** bâtiment pour respecter le pathfinding interne.
   - **Civils d'extérieur (`LOCAL` / `TRAVELER`) :** Les cibles de déplacement des unités qui marchent dehors doivent être des **GameLogics (`Logic`, `Land_HelipadEmpty_F`)**, des routes ou des coordonnées de terrain dégagé situées à l'extérieur.
   - **Anti-Empilement des IA :** Appliquer une dispersion aléatoire sur chaque position de destination (`_pos getPos [1 + random 3, random 360]`) afin que plusieurs unités ne ciblent pas la même coordonnée et ne traversent pas leurs corps respectifs.

```sqf
private _pos = getPosATL _logique;
_pos set [2, (_pos select 2) + 0.2];

private _grp = createGroup [civilian, true];
private _unit = _grp createUnit ["C_man_1", _pos, [], 0, "CAN_COLLIDE"];
_unit setPosATL _pos;
```

### Protection anti-collision au spawn
Après chaque `createUnit`, désactiver temporairement les dommages pendant **3 secondes** pour éviter les morts instantanées lors du chargement de la géométrie.

```sqf
_unit allowDamage false;
[_unit] spawn { sleep 3; (_this select 0) allowDamage true; };
```

### Distance minimale de sécurité (400m)
Toute tâche générée aléatoirement doit respecter des règles strictes de distance pour éviter le spawn sous les yeux du joueur :
- **Minimum 400m STRICT** entre le lieu de la tâche et le joueur (ne jamais descendre sous 400m).
- S'il y a plusieurs lieux pour une même tâche, ils doivent être espacés d'au moins **250m** entre eux.

### Ordre de spawn : secondaires avant principal
Quand une scène comporte une unité principale (chef, otage, cible...) et des secondaires (gardes) :
1. Faire spawner les **unités secondaires** en premier.
2. Les faire **patrouiller** aléatoirement dans la zone.
3. Attendre un délai de **1.5 seconde** entre chaque spawn secondaire.
4. Faire spawner l'**unité principale** en dernier.

---

## 3. Comportement des PNJ en attente d'interaction

### Variable de statut
Toujours attribuer une variable de statut au PNJ principal (`"WAIT"`, `"ACTION"`, `"DONE"`) pour gérer le flux du scénario. Plus besoin de synchronisation réseau.

```sqf
_unit setVariable ["LL_Task_Status", "WAIT"];
```

---

## 4. Règles des addActions de tâche

### Couleur jaune obligatoire
Les addActions **spécifiques à une tâche** (interaction avec un PNJ, désamorçage...) utilisent **toujours la couleur jaune** (`#FFFF00`). Les addActions permanentes d'escouade/support restent blanches.

```sqf
_unit addAction [
    format ["<t color='#FFFF00'>%1</t>", localize "STR_LL_Task_XX_Action"],
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        // Lancement direct de la suite du scénario
        ["scenario", _arguments] spawn LL_fnc_taskXX;
    },
    ...
];
```

### Distance d'interaction & Anti-double déclenchement
La condition de visibilité doit forcer le joueur à s'approcher (ex: `_this distance _target < 4`).
Toujours utiliser une variable de verrouillage locale pour éviter qu'un scénario se déclenche deux fois.

```sqf
if (missionNamespace getVariable ["LL_TaskXX_Triggered", false]) exitWith {};
missionNamespace setVariable ["LL_TaskXX_Triggered", true];
_target removeAction _id; 
```

---

## 5. Règles de gestion des tâches

### Création de tâche (Comportement Vanilla Arma 3)
Nous utilisons le système de tâches **Vanilla** (`BIS_fnc_taskCreate`). 

**Bonnes pratiques d'immersion (À implémenter pour chaque nouvelle tâche) :**
1. **Affichage 3D (HUD) :** Le 9ème paramètre (`visibleIn3D`) contrôle si l'icône flotte en permanence dans le monde 3D. Par défaut sur `false` (s'affiche uniquement si la tâche est assignée activement par le joueur). À activer sur `true` si la navigation requiert un indicateur visuel constant.
2. **Icônes Spécifiques :** Ne pas se contenter des icônes génériques (`"move"`, `"defend"`). Utiliser la bibliothèque d'icônes précises d'Arma 3 : `"kill"` (Cible HVT), `"interact"` / `"heal"` (Otages/Civils), `"takeoff"` (Extraction), `"destroy"`, `"search"`, `"documents"`.
3. **Hiérarchie (Parent/Enfant) :** Pour éviter d'encombrer l'écran, groupez les tâches. Au lieu d'un simple ID `"task_name"`, utilisez un tableau `["task_enfant", "task_parent"]` pour créer des sous-objectifs clairs.

```sqf
[
    true, // TOUJOURS 'true' (tous les joueurs jouables) pour garder les tâches actives en cas de mort (fn_switchToAI)
    ["task_XX_nom"], // Ou ["task_enfant", "task_parent"]
    [
        localize "STR_LL_Task_XX_Desc",
        localize "STR_LL_Task_XX_Title",
        localize "STR_LL_Task_XX_Marker"
    ],
    _positionObjectif,
    "AUTOASSIGNED", // Assigne la tâche automatiquement
    5,
    true,        // Notification activée ("Nouvelle Tâche")
    "interact",  // Icône de tâche SPÉCIFIQUE (kill, interact, takeoff, destroy...)
    false        // visibleIn3D = false -> Le marqueur 3D s'affiche UNIQUEMENT si assigné.
] call BIS_fnc_taskCreate;
```

### Amélioration de l'Intel et du Briefing
- **Liens de Marqueurs :** Dans les textes XML, utiliser `<marker name='nom_du_marker'>Texte cliquable</marker>`. Dans le briefing en jeu, cliquer sur ce texte en orange centrera automatiquement la carte sur l'objectif.
- **Intel Physique :** Placer des objets physiques (documents, laptops) avec un `addAction` pour révéler de nouvelles pages secrètes dans le briefing via `createDiaryRecord`.

### Suivi en temps réel sur la carte
Puisque la mission est Solo, vous pouvez **sans aucun problème** utiliser les commandes globales de marqueurs (`createMarker`, `setMarkerPos`) dans une boucle pour mettre à jour la position d'une cible en mouvement. La notion de surcharge réseau n'existe pas ici.

### Fin de mission : Extraction Automatique
**Aucune tâche ne déclenche directement la fin de mission.**  
À la fin d'une tâche (`SUCCEEDED` ou `FAILED`), la variable `LL_g_taskInProgress` repasse à `false`. Le `fn_taskManager.sqf` détecte ce changement et déclenche l'extraction (`LL_fnc_extraction`). L'hélico embarquera le joueur et déclenchera la fin de partie.

## 6. Séquencement des Tâches Obligatoires (A, B, C)

Les tâches de base ne sont **jamais** écrites en dur dans le fichier de menu ou le `task_generator`. Elles sont structurées dans leurs propres fichiers dans `Functions\Task` :
- **TaskA (Se rendre sur les lieux) :** Démarrée 15 secondes après l'introduction. Elle se valide automatiquement si le joueur s'approche à moins de 550m du marqueur d'objectif. Elle lance ensuite la TaskB.
- **TaskB (Protéger la population) :** Lancée à la complétion de la TaskA. Gère le spawn de civils. Elle est validée à la toute fin de la mission (dans l'hélicoptère d'extraction) si aucun civil de l'opération n'est mort.
- **TaskC (Extraction en toute sécurité) :** Démarrée 5 secondes après l'introduction. Elle est validée à la toute fin (dans l'hélicoptère d'extraction) si toute l'équipe est en vie.

---

## 7. Placement des positions de rendez-vous

- **Priorité aux Game Logics :** Toujours rechercher les Game Logics placées dans l'éditeur.
- **Filtres de distance :** Minimum 400 mètres du joueur. S'élargit par paliers progressifs (+50m) si aucun lieu n'est disponible.
- **Anti-Superposition (Tâches Multiples) :** Lors du chargement simultané de plusieurs tâches optionnelles par `fn_taskB.sqf`, les emplacements sélectionnés (`Logic` ou `Helipad`) doivent être enregistrés dans le tableau global `LL_g_usedTaskPos`. Chaque tâche doit filtrer sa liste d'apparition pour exclure tout point situé à moins de 15m d'un point déjà utilisé, évitant ainsi le chevauchement d'objectifs.
- **Conflit Héliport/Véhicule :** Si la tâche nécessite de faire apparaitre un **véhicule** (ex: Camion citerne, Tigris, blindé) sur une position d'apparition qui se trouve être un `Land_HelipadEmpty_F`, il faut **absolument supprimer (deleteVehicle) cet héliport invisible** lors du spawn. Sinon, les hélicoptères d'extraction/support du jeu risquent de s'y poser en plein sur le véhicule, causant une explosion.
- **Espacement :** 250 mètres minimum entre chaque sous-objectif.

---

## 7. Règles de briefing

Chaque nouvelle tâche doit ajouter au moins une entrée dans le journal du joueur (`createDiaryRecord`) avec un **titre** et un **texte**.
**Rappel :** Arma 3 affiche les `createDiaryRecord` en ordre chronologique inverse. Créer d'abord les sections secondaires, puis l'OPORD principal en dernier.

**Important (Compatibilité Transfert d'IA) :**
Pour que les journaux soient conservés si le joueur meurt et prend le contrôle d'une IA de l'escouade (`fn_switchToAI.sqf`), n'utilisez pas `player createDiaryRecord`. Assignez-le à tout le groupe via une boucle locale :
```sqf
{ _x createDiaryRecord ["diary", ["Titre", "Texte"]]; } forEach (units group player);
```

---

## 8. Immersion et rejouabilité

### Patrouilles Dynamiques
- Les groupes ennemis activés ne restent pas statiques, ils patrouillent.
- Les gardes d'un PNJ allié : Patrouille `LIMITED` / `SAFE` (rayon 4–18m).
- Les gardes d'un PNJ ennemi : Patrouille `COMBAT` (rayon 4–25m, ou plus).
- Toujours créer des petits groupes (2 ou 3 IA) avec des zones de patrouille asymétriques (15m, 25m, 55m...).

### Voix Native Immersive (PNJ)
Pour faire parler un PNJ dans sa langue natale sans animation faciale complexe :
```sqf
private _pnjGrp = group _pnj;
private _dummy = _pnjGrp createUnit ["O_Soldier_F", getPos _pnj, [], 0, "NONE"];
_dummy hideObjectGlobal true;
_dummy allowDamage false;
_dummy disableAI "ALL";
_pnjGrp selectLeader _pnj;

_dummy commandMove (getPos _pnj getPos [500, random 360]); // Fait parler le PNJ
sleep 3;
deleteVehicle _dummy;
```

---

## 9. Déplacement et suppression des I.A inutiles

À la fin d'une tâche, on utilise la fonction `LL_fnc_taskCleanup` pour gérer les IA restantes :
```sqf
[_guards] spawn LL_fnc_taskCleanup;
```
- **> 1500m :** Suppression immédiate (`deleteVehicle`).
- **Ennemis < 1500m :** Forment des groupes d'assaut tactiques pour traquer le joueur.
- **Alliés/Civils < 1500m :** Fuient vers un point éloigné et disparaissent proprement.

---

## 10. Conventions de nommage

| Élément | Convention | Exemple |
|---|---|---|
| ID de tâche | `task_XX_nom` | `task_01_recon` |
| Variable de déclenchement | `LL_TaskXX_NomAction` | `LL_Task01_Triggered` |
| Variable de statut PNJ | `LL_Task_Status` | `"WAIT"` / `"ACTION"` |
| Clé STR tâche | `STR_LL_Task_XX_*` | `STR_LL_Task_01_Action` |
| Variable globale | `LL_g_nomVariable` | `LL_g_usedTaskPos` |
| Fonction tâche | `LL_fnc_taskXX` | `LL_fnc_task01` |
| Fonction de nettoyage | `LL_fnc_taskCleanup` | `LL_fnc_taskCleanup` |

---

## 11. Migration des Tâches Optionnelles (D)

> **INFORMATION IMPORTANTE POUR LE DÉVELOPPEMENT FUTUR**
> Toutes les tâches optionnelles sont **déjà codées et fonctionnelles**. Leur logique, leurs scénarios et leurs triggers existent actuellement dans le dossier `Functions\Task` sous les anciens noms de fichiers (`fn_task00.sqf` à `fn_task08.sqf`).
> 
> **Le travail restant sur ces tâches consiste uniquement à :**
> 1. **Optimiser** et nettoyer le code existant de ces fichiers `fn_taskXX.sqf`.
> 2. **Migrer** cette logique dans les nouveaux fichiers de structure prévus à cet effet (`fn_taskD_*.sqf`).
> 3. Supprimer l'utilisation des fichiers séparés `_addAction.sqf` et centraliser la logique dans le fichier principal de la tâche.
> 4. **Ne JAMAIS utiliser `createMarker` avec `mil_objective` ou de gros marqueurs manuels** pour indiquer les cibles (cela surcharge la carte). Utilisez exclusivement les destinations natives de `BIS_fnc_taskCreate` ou `BIS_fnc_taskSetDestination` pour que l'icône de la tâche s'affiche proprement.

### État de la migration (To-Do List)

**Tâches Terminées (Faites) :**
- [x] **TASK_HVT** (`fn_taskD_hvt.sqf`) - Éliminer le Commandant HVT.
- [x] **TASK_DOCUMENTS** (`fn_taskD_documents.sqf`) - Migrer depuis `fn_task01.sqf` (Fouiller l'officier pour les registres).

**Tâches Restantes (À faire) :**
- [x] **TASK_TRANSMISSION** (`fn_taskD_transmission.sqf`) - Migrer depuis `fn_task03.sqf` (Détruire les stations radio).
- [x] **TASK_CAPTIVE** (`fn_taskD_captive.sqf`) - Migrer depuis `fn_task00.sqf` (Libérer l'agent captif).
- [x] **TASK_CHEMICAL** (`fn_taskD_chemical.sqf`) - Migrer depuis `fn_task04.sqf` (Élinguer la citerne chimique sans la détruire).
- [x] **TASK_TIGRIS** (`fn_taskD_tigris.sqf`) - Migrer depuis `fn_task08.sqf` (Détruire le brouilleur et la DCA Tigris).
*(Note : l'ancienne `task07` sur le char Angara semble avoir été remplacée/abandonnée au profit de TASK_HVT dans le gestionnaire).*
