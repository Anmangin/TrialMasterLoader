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
   Les chemins vers les répertoires de travail (`dir_path`, `path`, etc.) doivent être correctement définis pour s'adapter à votre environnement.

2. **Variables globales :**
   Le script utilise des variables globales `path`, `pathin`, et `pathout` pour spécifier les dossiers de travail et de sortie.

### Exemple de Fichier de Configuration

```sas
%let dir_path = R:\test;
%global path pathin pathout;
%let path=\\nas-01\SBE_ETUDES\MEDEA\8 - DM\SAS;

/* Inclure la macro git_utils */
%include "&dir_path\git_utils.sas";

/* URL du dépôt Git à cloner */
%let git_url = https://github.com/sbemangin/TrialMasterLoader.git;
