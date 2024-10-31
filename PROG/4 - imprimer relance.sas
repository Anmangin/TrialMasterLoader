
%let daterep=%sysfunc(today(),FRADFWDX.);


 /* 3 types de macro variable */
%let daterep=%sysfunc(today(),date8.);
%let datetemp=%sysfunc(today(),yymmdd9.);
data _null_;test=strip("&datetemp");datefileL=tranwrd(test,"-",".");call symputx('datefile',datefileL);run;

%macro CreatFolder(dossier);
option NOXWAIT;	 /* pecifies that the command processor automatically returns to the SAS session after the specified command is executed. You do not have to type EXIT. */
x mkdir "&dossier.";  /* créer le dossier en commande dos */
%mend;
%CreatFolder(&pathout\DOSSIER\&datefile.);

%macro print_site(SITEC);
ods excel file="&pathout\DOSSIER\&datefile.\&datefile. &SITEC  relance .xlsx" 
options(sheet_name="Missing form") ; 
proc print data=Formstatus label noobs; var SUBJID VISITN CRFName CRFInsNo CRFStat links; where SITEC="&SITEC" and CRFStat="Due";run;

ods excel options(sheet_name="DCR") ; 
proc print data=DCR label noobs;  
var SUBJID VISITN CRFName CRFInsNo QuestTxt responseTXT Comment ;where SITEC="&SITEC";run;


ods excel close;
%mend;

%macro get_all_site();
proc sql noprint; create table allsite as select distinct SITEC from Formstatus where  CRFStat="Due" ORDER BY SITEC;quit;
/*Remarque si un centre n'a pas de fiche en statut due, il n'apparait pas dans la table allsite, il faut alors retirer le where */
data _null_; set allsite end=endsite;
call symputx("SITEC"||left(_N_),SITEC);
if endsite then call symputx("nbsite",_N_);
run;
%do i=1 %to &nbsite;
%print_site(&&SITEC&i);
%end;
%mend;
%get_all_site;
