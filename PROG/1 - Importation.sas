/****************************************************************************************************************
                                           Fichier de relance TrialMaster, Etude MEDEA
****************************************************************************************************************/

/* Description du dossier :
- dossier IN : contient les elements a importer, directement issu du telechargement de TrialMaster apres avec decompressÃ© l archive.
- Dossier OUT : c est ici qu on stock la base qu on va lire dans sas et toutes les sorties.


   - Les queries doivent etre importees dans le fichier Queries.xlsx.
*/

%macro check;
 %if %symexist(path) = 0 %then %do;
        %put ERROR: importation.sas la macrovariable path &path n a pas ete definit.;
    %end;
%mend;
%check;
%let pathin = &path\IN;      /* Chemin d entree contenant les fichiers XPT de l etude */
%let pathout = &path\OUT;    /* Chemin de sortie pour les fichiers exportes */

/****************************************************************************************************************
                                          FICHIER STANDARD POUR L IMPORTATION D UNE ETUDE MACRO4 DANS SAS
****************************************************************************************************************/
/* Cree par Anthony, diffuse le 16.05.2018
   Objectif : Ce fichier a pour but de creer l ensemble des macros necessaires pour importer une etude. 
   Generalement, on l appelle grace a la fonction %INCLUDE.
*/

/* Declaration de deux macros variables pour les dates */
%let daterep = %sysfunc(today(), date8.);
%let datefile = %sysfunc(tranwrd(%sysfunc(today(), yymmdd10.), -, .));

/* Macro pour creer un dossier */
%macro CreatFolder(dossier);
    option NOXWAIT;  /* Permet de retourner automatiquement a SAS apres l execution de la commande */
	%if %sysfunc(fexist(&dossier)) = 0 %then %do;
    x mkdir "&dossier.";  /* Creation du dossier en commande DOS */
	%end;
	%else %put NOTE: le dossier &dossier existe deja.;
%mend;

/* Macro Getlib : Cree un dossier et le place en libname */
%macro Getlib(nom, dossier);
    option NOXWAIT;  
    %if %sysfunc(fexist(&basefile)) = 0 %then %do;
        x mkdir "&dossier.";  /* Creation du dossier en commande DOS si inexistant */
    %end;
    libname &nom "&dossier."; /* Assignation de la libname */
    %vider(&nom);  /* Appel de la macro pour vider le contenu si necessaire */
%mend;

/* Macro pour creer une table de noms */
%macro getnomtable(stu);
    /* Creation d une table nommee nomtable dans WORK avec la liste des tables presentes dans la libname specifiee */
    %let stuMaj = %sysfunc(UPCASE(&stu.));
    data nomtable;
        set sashelp.vstable;
        where libname = "&stuMaj";
        /* Suppression des tables non necessaires */
        if memname in ("CLINICALTRIAL", "QGROUP", "QGROUPQUESTION", "STUDYVISITCRFPAGE", "DATAITEMRESPONSE", 
                       "SITE", "DATAITEM", "CRFELEMENT", "CRFPAGE", "CRFPAGEINSTANCE", 
                       "DATAITEMVALIDATION", "MACROCOUNTRY", "MIMESSAGE", "STUDYVISIT", 
                       "TRIALSITE", "TRIALSUBJECT", "VALIDATIONTYPE", "VALUEDATA", 
                       "TEMP", "FICMYFN", "FM", "FINAL", "NOMTABLE", "TRIAL", 
                       "VISIT", "VISIT1", "PAT", "ERROR") then delete;
    run;
%mend;

/* Macro pour supprimer une table */
%macro suppr(table);
    %put Activation de la macro suppr : suppression de la table &table;
    proc sql noprint; 
        drop table &table;
    quit;
%mend;

/* Macro pour vider toutes les tables d une libname */
%macro vider(lib);
    %put Macro vider activee : lib = &lib;
    data nomtable;
        set sashelp.vstable;
        where libname = "&lib.";
        if memname in ("TIMEDOWN", "timedown", "nomtable") then delete;
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
        %put ERROR: Le dossier &basefile n existe pas;
    %end;
    %else %if %sysfunc(libref(&Libname)) NE 0 %then %do;
        %put ERROR: La libname &Libname n a pas ete creee;
    %end;
    %else %if %sysfunc(fexist(&XPTpath)) NE 0 %then %do;
        %put ERROR: Le dossier &XPTpath n existe pas;
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
            where find(fichier, ".xpt") > 0;
        run;

        proc sql noprint;
            select count(*) into :nbtable from FicmyFN;
        quit;

        data _null_;
            set FicmyFN end = findetable;
            call symputx("fichier" || left(_N_), fichier);
            call symputx("nomtable" || left(_N_), substr(fichier, 1, length(fichier) - 4));
            if findetable then call symputx("nbtable", _N_);
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

proc format ;
value $ate;
value $ime;
run;


/* Macro pour charger les donnees */
%macro dataLoad(DB = 0, note = 0, status = 0, format = 1);

    %if %symexist(pathin) = 0 or %symexist(pathout) = 0 or %symexist(path) = 0 %then %do;
        %put ERROR: Macros SBE : La macrovariable "pathin" (&pathin) , "pathout" (&pathout) et path  &path doivent etre declarees;
    %end;
    %else %do;
        %if &format %then %do;%include "&pathin/procformat.sas";%end;
        %if &DB %then %do;%openFile(DB, &pathin., &pathout\DB);%end;
        %if &note %then %do;%openFile(Note, &pathin.\Notes, &pathout.\Notes);%end;
        %if &status %then %do;%openFile(Status, &pathin\AuditStatus, &pathout\Status);%end;
    %end;
%mend;

%put NOTE: ########################### Chargement des macros d importation termine #######################;
