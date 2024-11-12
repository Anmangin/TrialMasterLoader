# TrialMaster Loader

Ce programme SAS ouvre et traite en boucle des fichiers XPT exportés depuis TrialMaster. Il utilise `git_utils.sas`, une macro SAS permettant d'interagir avec Git, disponible sur le dépôt [DanChaltiel/macro_sas](https://github.com/DanChaltiel/macro_sas). 

## Table des matières
- [Prérequis](#prérequis)
- [Configuration du Programme](#configuration-du-programme)
- [Installation et Utilisation de Git avec SAS](#installation-et-utilisation-de-git-avec-sas)
- [Fonctionnalités Principales](#fonctionnalités-principales)
  - [`%dataLoad`](#fonction-dataload)
  - [`%CreatableTableRelance`](#fonction-creatablerelance)
- [Structure des Fichiers Importés et Critères](#structure-des-fichiers-importés-et-critères)
- [Exemple Complet](#exemple-complet)

---

## Prérequis

1. **Télécharger `git_utils.sas` :** Téléchargez ce fichier depuis le dépôt GitHub de Dan Chaltiel et placez-le dans le même dossier que votre script principal.
2. **Accès aux chemins :** Assurez-vous d'avoir les autorisations nécessaires pour accéder aux chemins définis dans le script.

## Configuration du Programme

1. **Définition des chemins :**
     dir_path : c'est le dossier ou se trouve vos programmes SAS. 
     path : c'est l'endroit ou seront stocké les dossier IN et OUT

2. IN
    on met dans IN les fichier décompréssé de l'export TrialMaster. ne pas oublier de choisir de sortir le fichier format.sas aussi. il ne faut pas déplacer ou renommer les fichiers.

3 OUT
  une fois Lu les différentes tables sont sockées ici. on y retrouve aussi "par defaut" les fichier qui peuvent etre généré.

  

4. **Variables globales :**
   `pathin`, et `pathout`  sont importante et ne DOIVENT PAS ETRE MODIFIé. c'est déjà paramétré dans 1-Importation.

### Exemple de Fichier de Configuration

```sas
/******************************************************************************
* Programme: Chargement de relance général (GITHUBTrialMasterLoader)
* Description: Ce programme permet de charger les donnees d'un étude TM
*              en utilisant un utilitaire Git pour integrer les macros SAS
*              et des fonctions de chargement de donnees.
* Auteur: Anthony Mangin
* Date de creation: 2024-11-04
* Notes: Utilise le script "git_utils.sas" pour installer et gerer les macros
*        necessaires depuis un depot Git.
******************************************************************************/
%global path pathin pathout DATEFILE study;   /* Declaration des variables globales ne pas toucher*/

/* -------------------------PARTIE A CUSTO------------------------------------------*/
/* Declaration des chemins et variables globales */
/* Chemin reseau pour les fichiers de l'etude */
%let path = C:\Users\a_mangin\Documents\montest;

%let study=BETTER2;


/* -------------------------NE PAS TOUCHER AU RESTE SANS SAVOIR CE QU'ON FAIT ! ------------------------------------------*/



/* Inclusion de l'utilitaire Git pour gerer les macros depuis le depot Git */

%let dir_path = \\nas-01\SBE\05 - Data Managers\TrialMaster Data Manager\SAS\GITHUB;   /* Chemin local pour les fichiers de test */
%include "&dir_path\git_utils.sas";  /* Chemin du script d'installation Git */



/* URL du depot Git contenant les macros de chargement de donnees */
%let git_url = https://github.com/Anmangin/TrialMasterLoader.git;

/* Installation de la version specifique des macros depuis le depot Git */
%install_git(dir_path = &dir_path, git_url = &git_url, version =c6b678d, local_folder = git_TrialMasterLoader);

/* Affichage de messages de log pour la version installee */
%put WARNING: INSTALL_GIT: git_macro_version = &git_macro_version;
%put &pathin; /* Chemin d'entree pour confirmation */

option mprint=no;
/* Execution de la macro de chargement de donnees avec des parametres specifiques */
%dataLoad(DB = 1, note = 1, status = 1);

/* Creation d'une table de relance si necessaire */
%CreatableTableRelance;
```
dataLoad est construit dans 1-importation,
il permet de delectionner les infos à importer :
```sas
%dataLoad(DB = 0, note = 0, status = 0, format = 1);
```
pas defaut DV,note,status sont false, et format est True.
pour une analyse, on peut charger uniquement DB. pour travailler sur les relance, il faut en plus Note et Status.


```sas
%CreatableTableRelance;
```
ce code Crée 2 table dans la work : DCR et FormStatus. le code ne se lance que si les libnames Note et Status existe, alors il ne faut pas s'amuser a renommer.  la première contient les queries de TrialMaster, et le second la liste des fiches de votre études avec les statuts (No data, Incomplete, Complete, etc.)
