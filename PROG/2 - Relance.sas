
************************************************************************************************************************************************************************
                                                               Fichier de de relance TrialMaster, Etude Better2
************************************************************************************************************************************************************************
------------------ ne rien toucher après ici ---------------------
Description du dossier :
dossier DB : contient les données de l'étude exporté
dossier Status : contients les statuts eporté de l'etude
dossier IMP : contients les éléments a importer.
au niveau de l'export dans trialmaster, il est important de choisir XportSas et codelist = Yes.
l'imports des queries doit etre faire dans le fichier Queries.xlsx;
;
	
	

%let base=https://ecrftm50.gustaveroussy.fr/50036/TrialMaster/Form/ICrf/;

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


%macro creation_DCR;

%getnomtable(NOTE);	 /* création de nomtable, la liste des tables dans NOTE */

  data _null_;
set nomtable end=finalf;
call symputx('memname'||left(_N_),memname);	/* chargement du nom de la table dans &memname1 / &memname2 / etc... pour la boucle */
if finalf then call symputx('nbtable',_N_); /* création de la macro variable &nbtable le nombre de table dans la librairie note */
run;


%do i=1 %to &nbtable; /* on crée une boucle pour gerer toutes les tables  1 à 1 */
%put travail sur la table &&memname&i;



/* evaluation des formats dans la table chargé */

proc contents noprint data=db.&&memname&i out=temp_format;run;
 	%if &i=1 %then %do;data format_db;set temp_format;run;%end;  /* chargement dans format_db à la premiere itération */
%if &i>1 %then %do;data format_db;set format_db temp_format;run;%end;  /* chargement dans format_db dans les autres itérations  dans éliminer les informations déjà chargé */


 /* Chargement des notes brut dans la table tempDCR */

data tempDCR2;set status.&&memname&i;run;
data tempDCR3;set note.&&memname&i;run;


proc sql noprint; create table tempDCR as select a.*, VISIT1 from tempDCR3 a left join tempDCR2 b on a.TRNO=b.TRNO and a.STNO=b.STNO and a.CRFInsNo=b.CRFInsNo and a.PATIENTI=b.PATIENTI  and a.formid=b.formid and a.visitid=b.visitid ;quit;
 proc sort; by TrlObjec DetailNo;run; 
data tempDCR;set tempDCR;by TrlObjec; if last.TrlObjec;run;

%if &i=1 %then %do;data DCR;set tempDCR;run;%end;  /* chargement dans DCR à la premiere itération */
%if &i>1 %then %do;data DCR;set DCR tempDCR;run;%end;  /* chargement dans DCR dans les autres itérations  dans éliminer les informations déjà chargé */
%end;
 data DCR;set DCR;if CURSTATE="No Query" or CURSTATE="Responded" or CURSTATE="Closed" then delete;run;
 
%suppr(tempDCR);%suppr(tempDCR2);%suppr(tempDCR3);%suppr(nomtable);%suppr(temp_format);

/* chargement des formats associé dans la table DCR */
proc sort data=format_db nodupkey;by NAME;run;
proc sql noprint; create table DCR_temp_format as select dcr.*,FORMAT,TYPE from dcr left join format_db on NAME=CTVar;quit;
data DCR; set DCR_temp_format;format responseTXT $50.; ;run;
 %suppr(DCR_temp_format);

/* par defaut, DCR contient les codes sans les formats, ici on crée la variable responseTXT qui contient la décode pour les catégories et les dates */

data _null_;
set DCR end=finalf;
call symputx('F'||left(_N_),FORMAT);
if finalf then call symputx('NBDCR',_N_);
run;


data DCR;
set DCR;
if format NE "" then temp=input(strip(response),10.);
%do var=1 %to &NBDCR;
%if "&&F&var." NE "" and &&F&var. NE DATE %THEN if _N_=&var and Response NE "" then responseTXT=put(temp,&&F&var...) %str(;);
%end;
if format="DATE" and response NE "" then responseTXT=cats(substr(response,9,2),'/',substr(response,6,2),'/',substr(response,1,4));
run;


data dcr;
set dcr;
if responseTXT="" then responseTXT=response;
format links $1000.;
links=cats("&base",  FORMID ,'?returnUrl=%2F50036%2FTrialMaster%2FPatientListView%2FSelectPatient?uniqueReportingGridId%3D17000000%26id%3D' , PATIENTI , '%26ngrd%3D1');
run;
%suppr(format_db);


 data dcr;
 retain  TRCAP TRIALID SITEC SITEID SUBJID PATIENTI VISIT1 VISITN VISITID	CRFName  CRFInsNo FORMID CRFStat Group GRPINSNO QuestTxt  responseTXT MsgType CURSTATE Comment CTACTDTC FromUser links;
 set dcr;
 label 
TRNAME	= "Study"
TRNO	="Study Number"
TRCAP	="Trial Caption"
TRSPON	="Site"
TRIALID	="Study Identificator TrialMaster"
STNAME = "Site Name"
STNO   = "Site Number"
SITEC	= "Site Caption"
SITEID	= "Site Identificator TrialMaster"
SUBJINIT = "Patient Initials"
PTACTV	 = "Activation patient"
PTDROP	 = "Dropped patient"
PTENRL	 = "Enrolled patient"
PTRNO	 = "Patient Trial Number"
PATIENTI = "Patient Identificator TrialMaster"
VISITN	 = "Visite Name"
VISITID	 = "Visit Identificator TrialMaster"
CRFName	 ="Form Name"
CRFInsNo = " Form Number of Repetition"
CRFStat	 = "Status of Form"
FORMID	 = "Form Identificator TrialMaster"
Group	 = "Group Name"
GRPINSNO =	"group Number Repetition"
CTVar	 =  "Question Code"
QuestTxt = "Label of Question"
Response = "Brut response (code)"
ThreadNo = "internal Number of DCR"
CURSTATE   = "Status of DCR"
Comment = "Queries"
links="Lien Form"
;
keep   TRCAP TRIALID SITEC SITEID SUBJID PATIENTI VISIT1 VISITN VISITID	CRFName  CRFInsNo FORMID CRFStat Group GRPINSNO QuestTxt  responseTXT MsgType CURSTATE Comment CTACTDTC FromUser links
; 
run;


proc sql noprint; create table dcr_t as select a.* ,visit3 from dcr a left join db.Visit b on a.Visitn=b.Visitn;quit;
proc sort; by SITEC SUBJID VISIT1 FORMID ;run;





%mend;


%creation_DCR;









%macro relance;

	%getnomtable(STATUS);	 /* création de nomtable, la liste des tables dans NOTE */

  data _null_;
set nomtable end=finalf;
call symputx('memname'||left(_N_),memname);	/* chargement du nom de la table dans &memname1 / &memname2 / etc... pour la boucle */
if finalf then call symput('nbtable',_N_); /* création de la macro variable &nbtable le nombre de table dans la librairie note */
run;


%do i=1 %to &nbtable;
	/* on prends tous les status pour les mettre dans FormStatus */
data temp_FormStatus;set STATUS.&&memname&i;run;
%if &i=1 %then %do;data FormStatus;set temp_FormStatus;run;%end;
%if &i>1 %then %do;data FormStatus;set FormStatus temp_FormStatus;run;%end;
%end;

  %suppr(temp_FormStatus);
   %suppr(nomtable);

   /* Création de VDAT dans un format adapté */
data FormStatus;set FormStatus;vn=VISIT1*1;format VDAT DDMMYY10.;if VISDAT NE "" then VDAT=mdy(substr(strip(VISDAT),6,2),substr(strip(VISDAT),9,2),substr(strip(VISDAT),1,4));run;

/* on créécris zRespDat mais avec un bon format datetime exploitable */
data FormStatus;
set FormStatus;
day=substr(zRespDat,9,2);
month= substr(zRespDat,6,2);
year=substr(zRespDat,1,4);
hour=substr(zRespDat,12,2);
min = substr(zRespDat,15,2);
sec = substr(zRespDat,18,2);
dS1=mdy(month,day,year);
Ds2=HMS(hour,min,sec);
format ds1 ddmmyy10.;
format ds2 hhmm.;
ds3=DHMS(ds1, hour,min,sec);
format ds3 datetime20.;
drop day month year hour min sec ds1 ds2 zRespDat;
run;

data FormStatus;
set FormStatus;
rename ds3=zRespDat;
label zRespDat="datetime";
run;

  /* on va filtrer car a la base on importe tout l'historique, la on prend le dernier */
proc sort data=FormStatus;by FORMID zRespDat;run;
 data FormStatus;set FormStatus;by FORMID;if not last.FORMID then delete;run;
proc sort data=FormStatus;by PATIENTI VISITID  CRFInsNo FORMID;run;


 /* on vire le superflue, et on remet les chiffres dans le bon format */
data FormStatus; set FormStatus;nump=SUBJID*1; STN=STNO*1 ; drop TRNO SUBJID  VISDAT  SUBJINIT  VISIT1   STNO  ;run;


/* un peu d'ordre et de label */
data FormStatus; set FormStatus; rename nump=SUBJID VDAT=VISDAT  vn=VISIT1 STN=STNO;run;



data FormStatus ;retain TRNAME
STNAME
STNO
SITEID
SUBJID
VISITN
VISITID
CRFName
VISIT1
CRFInsNo
CRFStat
FORMID
zRespDat
zUserNam
zRoleNam
;
set FormStatus;
label STNO="Site Number" VISIT1="Visit Number";
label VISDAT="Date of Visit"
if VISIT1=. then VISIT1=200;
run;


 /* Sécurité on vérifie la présence de DCR avant d'ajouter le nombre de queries par fiche */
 %getnomtable(WORK);
 data nomtable; set nomtable; where memname="DCR";run;
 proc sql noprint; select count(*) into: pres_dcr from nomtable;quit;
 %suppr(nomtable);
 %put nombre de table DCR présent (1 attendu) : &pres_dcr ;
 %if &pres_dcr=1 %then %do;

 /*	   calcul et ajout de nbq "Number of queries" dans FormStatus */
proc sql noprint nowarn; create table rap as select  TRIALID,SUBJID,5. as SUBJID,PATIENTI,VISITID, FORMID,CRFInsNo, count(*) as nbq 'Number of queries' from DCR group by TRIALID,SUBJID,VISITID, FORMID,CRFInsNo,PATIENTI ;
create table FormStatus_temp as select FormStatus.*, nbq "Number of queries" from FormStatus a left join rap b on a.SUBJID=input(b.SUBJID,3.) and a.VISITID=b.VISITID and a.FORMID=b.FORMID and a.CRFInsNo=b.CRFInsNo ;quit;
quit;

data FormStatus;set FormStatus_temp;run;
%suppr(FormStatus_temp);
%suppr(rap);


%end;
/*création des liens */
data FormStatus;set FormStatus;
/* API decrypt : m=17 -> aller dans l'onglet Browse
  soid=-> selectionner le centre
   poid -> selectionner le patient
   &void=' ->		selectionner la visite
   &foid=' -> la fiche
  &otid=8&said=10 -> je sais pas mais ca marche
   tgn-> faire remplir le nom de l'étude automatiquement
	&un=-> faire remplir le pseudo automatiquement */
links=cats("&base",  FORMID ,'?returnUrl=%2F50036%2FTrialMaster%2FPatientListView%2FSelectPatient?uniqueReportingGridId%3D17000000%26id%3D' , PATIENTI , '%26ngrd%3D1');
;run;
	  proc sort; by SUBJID VISIT1 FORMID CRFInsNo;run;

%mend;
%relance;

proc sql noprint; create table site as select distinct sitec,STNAME from db.site;quit;

proc sql noprint; create table FormStatus2 as select sitec, FormStatus.* from FormStatus left join site on FormStatus.STNAME=site.STNAME;quit;
data FormStatus; set FormStatus2;run;
%suppr(FormStatus2);
%suppr(site);
/*%suppr(Format_db);*/
