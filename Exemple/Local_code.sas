/******************************************************************************
* Programme: Chargement des donnees de l'etude MEDEA
* Description: Ce programme permet de charger les donnees de l'etude MEDEA 
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
%let dir_path = R:\test;   /* Chemin local pour les fichiers de test */

/* Chemin reseau pour les fichiers de l'etude */
%let path = \\nas-01\SBE_ETUDES\MUCILA\8 - DM\SAS;

%let study=MUCILA;


/* -------------------------NE PAS TOUCHER AU RESTE SANS SAVOIR CE QU'ON FAIT ! ------------------------------------------*/



/* Inclusion de l'utilitaire Git pour gerer les macros depuis le depot Git */
%include "&dir_path\git_utils.sas";  /* Chemin du script d'installation Git */

/* URL du depot Git contenant les macros de chargement de donnees */
%let git_url = https://github.com/sbemangin/TrialMasterLoader.git;

/* Installation de la version specifique des macros depuis le depot Git */
%install_git(dir_path = &dir_path, git_url = &git_url, version =74f32a3, local_folder = git_TrialMasterLoader);

/* Affichage de messages de log pour la version installee */
%put WARNING: INSTALL_GIT: git_macro_version = &git_macro_version;
%put &pathin; /* Chemin d'entree pour confirmation */

/* Execution de la macro de chargement de donnees avec des parametres specifiques */
%dataLoad(DB = 1, note = 1, status = 1);

/* Creation d'une table de relance si necessaire */
%CreatableTableRelance;

/* Calcul des metriques ISO pour l'etude MEDEA */
%ISO_Metrics(study = &study, print = 0);


/*  Import de la table de contact pour faire les mail */
/*
il faut une table dans la work qui s'appelle contact, qui contient Email et STNO avec le numéro de centre (le meme que sur TM) */


%macro importXLS(table,adresse);
PROC IMPORT OUT= WORK.&table DATAFILE= &adresse DBMS = xlsx REPLACE;
GETNAMES=YES;
RUN;
%mend; 

%importXLS(contact,"\\nas-01\SBE_ETUDES\MUCILA\User Account\Centre & User V1.0.xlsx");
data contact;
set contact;
STNO=Number_Site*1;
mail=Email;
if  Email NE "" ;
run;



/* parametrer le CC */


global CC_mail;
%let CC_mail=toto.barbier@gustaveroussy.fr%str(;) Dan.chaltiel@gustaveroussy.fr;



%macro Corp_Message;
		proc odstext;
p "ETAT &study pour saisie avant analyse, demande urgente"/style={&Gtitre};

p "Bonjour à tous,"/style={&mybody};
p "Nous avons oublié d'inclure les fiches fin d'étude dans les relances.
afin de les saisir voici la liste des liens pour les remplir :"/style={&mybody};
p "j'en profite pour rajouter les requetes en cours non résolues.:"/style={&mybody};
p "en cas de problème n’hésitez pas à me contacter au 01.42.11.56.35 ,"/style={&mybody};
p "Bonne journée,"/style={&mybody};
p "Anthony Mangin"/style={&mybody};
run;
%mend;

%macro Corp_Signature;
		proc odstext;
p "Créé le &datefull par"/style={fontsize=12pt borderwidth=0px font_weight=bold};

p "Anthony Mangin"/style={fontsize=12pt  borderwidth=0px};
p "Data Manager"/style={fontsize=10pt borderwidth=0px};
p "Service de Biostatistique et Epidémiologie (SBE)"/style={fontsize=10pt borderwidth=0px };
p "Batiment B2M"/style={fontsize=10pt borderwidth=0px };
p "114, rue Edouard Vaillant,"/style={fontsize=10pt borderwidth=0px };
p "94805 Villejuif Cedex"/style={fontsize=10pt borderwidth=0px };
p "Tel : 01 42 11 56 36"/style={fontsize=10pt borderwidth=0px };
p "Fax : 01 42 11 52 51"/style={fontsize=10pt borderwidth=0px };
;run;

%mend;


%Run_relance(Form=1,queries=0,display=0);
