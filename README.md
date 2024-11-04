# TrialMaster Loader

Ce programme SAS ouvre et traite en boucle des fichiers XPT exportés de TrialMaster. Il s'appuie sur `git_utils.sas`, une macro SAS permettant d'interagir avec Git, disponible sur le dépôt [DanChaltiel/macro_sas](https://github.com/DanChaltiel/macro_sas). 

## Prérequis

1. **Télécharger `git_utils.sas` :** Téléchargez ce fichier depuis le dépôt GitHub de Dan Chaltiel dans le même dossier que votre script principal.
2. **Accès au répertoire local et au dépôt Git distant :** Assurez-vous d'avoir les autorisations nécessaires pour accéder aux chemins définis dans le script.

## Configuration du Programme

1. **Définition des chemins :**
   Les chemins vers les répertoires de travail (`dir_path`, `path`, etc.) doivent être correctement définis pour s'adapter à votre environnement.

2. **Variables globales :**
   Le script utilise des variables globales `path`, `pathin`, et `pathout` pour spécifier les dossiers de travail et de sortie.

3. **Exemple de Fichier de Configuration**

   ```sas
   %let dir_path = R:\test;
   %global path pathin pathout;
   %let path=\\nas-01\SBE_ETUDES\MEDEA\8 - DM\SAS;

   /* Inclure la macro git_utils */
   %include "&dir_path\git_utils.sas";

   /* URL du dépôt Git à cloner */
   %let git_url = https://github.com/sbemangin/TrialMasterLoader.git;

   
Installation et Utilisation de Git avec SAS
Installation
La macro %install_git permet de cloner un dépôt Git dans un dossier local spécifié. Dans cet exemple, le programme clone le dépôt TrialMasterLoader avec une version spécifique.

sas
Copier le code
%install_git(
    dir_path=&dir_path,       /* Chemin local d'installation */
    git_url=&git_url,         /* URL du dépôt Git */
    version=e0c495c,          /* Version du dépôt (commit hash) */
    local_folder=git_TrialMasterLoader /* Nom du dossier local */
);
Exemple de Chargement des Données
Le programme %dataLoad est utilisé pour charger les données en spécifiant des options de configuration.

sas
Copier le code
%dataLoad(
    DB=1,           /* Indicateur de base de données */
    note=1,         /* Option de note pour le chargement */
    status=1        /* Indicateur de statut pour le chargement */
);
Création des Tables de Relance
Pour générer les tables de relance, la macro %CreatableTableRelance est appelée avec les options nécessaires pour contrôler le processus.

sas
Copier le code
option mprint=no; /* Option pour désactiver l'affichage détaillé */
%CreatableTableRelance;
Résumé des Options
dir_path : Chemin du répertoire de travail où git_utils.sas est situé.
path : Chemin vers le répertoire de sortie pour stocker les résultats.
git_url : URL du dépôt Git à cloner et utiliser.
Avertissements
Ce programme est destiné à une utilisation en environnement sécurisé, et il est conseillé de vérifier les autorisations de lecture et d'écriture dans les répertoires spécifiés.

Exécutez ce code pour initialiser votre environnement SAS et pour automatiser l’import des fichiers XPT de TrialMaster. Ce guide fournit un aperçu de l’utilisation des macros SAS pour manipuler des fichiers et interagir avec Git en local.

go
Copier le code

Ce fichier `README.md` explique le rôle de chaque commande et comment configurer le programme pour une util
