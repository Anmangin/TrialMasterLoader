/****************************************************************************************************************
                                           Fichier de relance TrialMaster, Étude MEDEA
****************************************************************************************************************/

/* Description du dossier :
- dossier IN : contient les éléments à importer, directemenet issu du telechargement de TrialMaster après avec decompréssé l'archive.
-Dossier OUT : c'est ici qu'on stock la base qu'on ba lire dans sas et toutes les sorties.


   - Les queries doivent être importées dans le fichier Queries.xlsx.
*/


 %if %symexist(path) = 0 %then %do;
        %put ERROR: importation.sas la macrovariable path &path n`a pas été definit.;
    %end;

%let pathin = &path\IN;      /* Chemin d`entrée contenant les fichiers XPT de l`étude */
%let pathout = &path\OUT;    /* Chemin de sortie pour les fichiers exportés */

/****************************************************************************************************************
                                          FICHIER STANDARD POUR L`IMPORTATION D`UNE ÉTUDE MACRO4 DANS SAS
****************************************************************************************************************/
/* Créé par Anthony, diffusé le 16.05.2018
   Objectif : Ce fichier a pour but de créer l`ensemble des macros nécessaires pour importer une étude. 
   Généralement, on l`appelle grâce à la fonction %INCLUDE.
*/

/* Déclaration de deux macros variables pour les dates */
%let daterep = %sysfunc(today(), date8.);
%let datefile = %sysfunc(tranwrd(%sysfunc(today(), yymmdd10.), -, .));

/* Macro pour créer un dossier */
%macro CreatFolder(dossier);
    option NOXWAIT;  /* Permet de retourner automatiquement à SAS après l`exécution de la commande */
    x mkdir "&dossier.";  /* Création du dossier en commande DOS */
%mend;

/* Macro Getlib : Crée un dossier et le place en libname */
%macro Getlib(nom, dossier);
    option NOXWAIT;  
    %if %sysfunc(fexist(&basefile)) NE 0 %then %do;
        x mkdir "&dossier.";  /* Création du dossier en commande DOS si inexistant */
    %end;
    libname &nom "&dossier."; /* Assignation de la libname */
    %vider(&nom);  /* Appel de la macro pour vider le contenu si nécessaire */
%mend;

/* Macro pour créer une table de noms */
%macro getnomtable(stu);
    /* Création d`une table nommée nomtable dans WORK avec la liste des tables présentes dans la libname spécifiée */
    %let stuMaj = %sysfunc(UPCASE(&stu.));
    data nomtable;
        set sashelp.vstable;
        where libname = "&stuMaj";
        /* Suppression des tables non nécessaires */
        if memname in (`CLINICALTRIAL`, `QGROUP`, `QGROUPQUESTION`, `STUDYVISITCRFPAGE`, `DATAITEMRESPONSE`, 
                       `SITE`, `DATAITEM`, `CRFELEMENT`, `CRFPAGE`, `CRFPAGEINSTANCE`, 
                       `DATAITEMVALIDATION`, `MACROCOUNTRY`, `MIMESSAGE`, `STUDYVISIT`, 
                       `TRIALSITE`, `TRIALSUBJECT`, `VALIDATIONTYPE`, `VALUEDATA`, 
                       `TEMP`, `FICMYFN`, `FM`, `FINAL`, `NOMTABLE`, `TRIAL`, 
                       `VISIT`, `VISIT1`, `PAT`, `ERROR`) then delete;
    run;
%mend;

/* Macro pour supprimer une table */
%macro suppr(table);
    %put Activation de la macro suppr : suppression de la table &table;
    proc sql noprint; 
        drop table &table;
    quit;
%mend;

/* Macro pour vider toutes les tables d`une libname */
%macro vider(lib);
    %put Macro vider activée : lib = &lib;
    data nomtable;
        set sashelp.vstable;
        where libname = "&lib.";
        if memname in (`TIMEDOWN`, `timedown`, `nomtable`) then delete;
    run;
    
    proc sql noprint;
        select distinct count(*) into: nbtable from nomtable;
    quit;

    %do i = 1 %to &nbtable.;
        data _null_;
            set nomtable;
            if _N_ = &i then call symput("memname", memname);
        run;
        %suppr(&lib..&memname.);
    %end;
%mend;

/* Macro openFile : ouvre tous les fichiers XPT et les copie dans une libname */
%macro openFile(Libname, XPTpath, basefile);
    %getlib(&Libname, &basefile);
    %if %sysfunc(fexist(&basefile)) NE 0 %then %do;
        %put ERROR: Le dossier &basefile n`existe pas;
    %end;
    %else %if %sysfunc(libref(&Libname)) NE 0 %then %do;
        %put ERROR: La libname &Libname n`a pas été créée;
    %end;
    %else %if %sysfunc(fexist(&XPTpath)) NE 0 %then %do;
        %put ERROR: Le dossier &XPTpath n`existe pas;
    %end;
    %else %do;
        filename myFN "&XPTpath";
        data FicmyFN(keep = fichier);
            length fichier $50;
            retain did;
            did = dopen("myFN");
            if did > 0 then do;
                i = 1;
                do while (dread(did, i) ne "");
                    fichier = dread(did, i);
                    output;
                    i = i + 1;
                end;
                did = dclose(did);
            end;
        run;
        
        data FicmyFN;
            set FicmyFN;
            where find(fichier, `.xpt`) > 0;
        run;

        proc sql noprint;
            select count(*) into :nbtable from FicmyFN;
        quit;

        data _null_;
            set FicmyFN end = findetable;
            call symputx(`fichier` || left(_N_), fichier);
            call symputx(`nomtable` || left(_N_), substr(fichier, 1, length(fichier) - 4));
            if findetable then call symputx(`nbtable`, _N_);
        run;

        %do i = 1 %to &nbtable.;
            %put Import de la table &&fichier&i.;
            libname xptfile xport "&XPTpath\&&fichier&i.";
            proc copy in = xptfile out = &Libname;
            run;
        %end;
        
        %suppr(ficmyfn);
    %end;
%mend;

/* Format pour les dates */
proc format;
    value $ATE;
run;

/* Macro pour charger les données */
%macro dataLoad(DB = 0, note = 0, status = 0, format = 1);
    %if %symexist(pathin) = 0 or %symexist(pathout) = 0 or %symexist(path) = 0 %then %do;
        %put ERROR: Macros SBE : La macrovariable "pathin" (&pathin) ,"pathout" (&pathout) et path  &path doivent être déclarées;
    %end;
    %else %do;
		%if &format %then %include "&pathin\procformat.sas";
        %if &DB %then %openFile(DB, &pathin., &pathout\DB);
        %if &note %then %openFile(Note, &pathin.\Notes, &pathout.\Notes);
        %if &status %then %openFile(Status, &pathin\AuditStatus, &pathout\Status);
    %end;
%mend;

%put NOTE: ########################### Chargement des macros d`importation terminé #######################;
