
************************************************************************************************************************************************************************
                                                               Fichier de de relance TrialMaster, Etude MEDEA
************************************************************************************************************************************************************************
------------------ ne rien toucher après ici ---------------------

Description du dossier :
dossier DB : contient les données de l'étude exporté
dossier Status : contients les statuts eporté de l'etude
dossier IMP : contients les éléments a importer.
au niveau de l'export dans trialmaster, il est important de choisir XportSas et codelist = Yes.
l'imports des queries doit etre faire dans le fichier Queries.xlsx;
;





***************************************************************************************************************************************************************************

                                                              FICHIER STANDARD POUR L'IMPORTATION D'UNE ETUDE MACRO4 DANS SAS

***************************************************************************************************************************************************************************
Crée par Anthony, diffusé le 16.05.2018
objectif du fichier : ce fichier a pour but de créer l'ensemble des macro nécéssaire pour importer une étude. On l'appelle généralement grâce à une fonction %INCLUDE;

 /* 3 types de macro variable */
%let daterep=%sysfunc(today(),date8.);
%let datetemp=%sysfunc(today(),yymmdd9.);
data _null_;test=strip("&datetemp");datefileL=tranwrd(test,"-",".");call symputx('datefile',datefileL);run;

%include "&pathin\procformat.sas";


*createfolder : créer un dossier;
%macro CreatFolder(dossier);
option NOXWAIT;	 /* pecifies that the command processor automatically returns to the SAS session after the specified command is executed. You do not have to type EXIT. */
x mkdir "&dossier.";  /* créer le dossier en commande dos */
%mend;

* Getlib : crée un dossier et le place en libname;
%macro Getlib(nom,dossier);
option NOXWAIT;		/* pecifies that the command processor automatically returns to the SAS session after the specified command is executed. You do not have to type EXIT. */
x mkdir "&dossier."; /* créer le dossier en commande dos  NOTE: pas de message d'erreur si le dossier est déjà présent*/
libname &nom "&dossier.";/* création de la libname*/
%vider(&nom);
%mend;



%macro getnomtable(stu);
/*    création d'une table nommé nomtable dans la work avec la liste de table présent dans la libname appellé */
%let stuMaj=%sysfunc(UPCASE(&stu.));

data nomtable ;set sashelp.vstable;where libname="&stuMaj";
if memname='CLINICALTRIAL' or memname='QGROUP' or  memname='QGROUPQUESTION' or memname='STUDYVISITCRFPAGE' or memname='DATAITEMRESPONSE' or memname='SITE' or memname='DATAITEM' or memname='CLINICALTRIAL' or memname='CRFELEMENT' then delete;
if memname='CRFPAGE' or memname='CRFPAGEINSTANCE' or memname='DATAITEMVALIDATION' or memname='MACROCOUNTRY' or memname='DATAITEMVALIDATION' then delete;
if memname='MIMESSAGE' or memname='STUDYVISIT' or memname='TRIALSITE' or memname='TRIALSUBJECT' or memname='VALIDATIONTYPE' or memname='VALUEDATA' then delete;
if memname="TEMP" or   memname="FICMYFN"  or   memname="FM" or memname="FINAL" or memname="NOMTABLE"  or memname="TRIAL" or memname="SITE" or memname="VISIT" or memname="VISIT1"  or memname="PAT" or memname="ERROR" then delete;
run;
%mend;



%MACRO suppr(table);
%put activation de la macro suppr suppression de la table &table;
proc sql noprint; 
Drop Table &table;
quit;
%mend;


%macro vider(lib);
/*supprime toute les tables d'une Libname ;*/
%put macro vider activée  lib=&lib;
%let stu=%sysfunc(UPCASE(&lib.));
data nomtable ;set sashelp.vstable;where libname="&lib.";
if memname='TIMEDOWN' or memname='timedown' or memname="nomtable" then delete;
run;

proc sql noprint;select distinct count(*) into: nbtable from nomtable; quit;
%do i=1 %to &nbtable.;
data _null_ ;set nomtable; if _N_=&i then call symput("memname",memname) ; run;
%suppr(&lib..&memname.);
%end;
%mend;



****** macro openfile ***
* la macro open file ouvre tous les fichier XPT pour les copier dans une libname
input contient l'adresse du dossier a impoter, et output le nom de la libname ou placer les tables a importer;

%macro openFile(output,input);
	filename myFN "&input";
	Data FicmyFN(keep = fichier ); 
	length fichier $50; 
	retain did ; 
	did = dopen("myFN"); 
		if did > 0 then do; 
			i = 1; 
			do while (dread(did,i) ne "" ) ; 
				fichier = dread(did,i); 
				output;
				i = i + 1 ; 
			end; 
		did = dclose(did); 
		end; 
	Run;
	data FicmyFN;
	set FicmyFN;
	where find(fichier,'.xpt')>0;
	run;


	proc sql noprint; select count(*) into : nbtable from FicmyFN;quit;
	data _null_; set FicmyFN end=findetable; 
	call symputx('fichier'||left(_N_),fichier);
	call symputx('nomtable'||left(_N_),substr(fichier,1,length(fichier)-4));
	if findetable then call symputx('nbtable',_N_);
	run;
	%do i=1 %to &nbtable;
		%put import de la table &&fichier&i.;
	libname xptfile xport  "&input\&&fichier&i.";
	proc copy in=xptfile out=&output;run;
	%end;
%suppr(ficmyfn);
%mend;



********************** IMPORT DES STATUS *********************************;
%getlib(Status,&pathout\Status);
%openFile(Status,&pathin\AuditStatus);
********************** IMPORT DES DONNéES *********************************;
%getlib(DB,&pathout\DB);
%openFile(DB,&pathin.);

%getlib(Note,&pathout.\Notes);
%openFile(Note,&pathin.\Notes);


/*-> pour le pb des format de date */
proc format;
value $ATE;
run;
