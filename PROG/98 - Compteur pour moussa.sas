%let path=\\nas-01\SBE_ETUDES\MEDEA\8 - DM\SAS;

%let pathin=&path\IN;*a adatper a l'étude;
%let pathout=&path\OUT;*a adatper a l'étude;
%let study=MEDEA;

proc format ;
value $ate;
value $ime;
run;



%include "&path\PROG\1 - Importation.sas.sas";
%include "&path\PROG\2 - Relance.sas";
%include "&path\PROG\3 - Calcul perso.sas";

   
proc sql noprint; create table  nbpat as select STNAME, count(*) as nbpat from db.pat group by STNAME;quit;



proc sql noprint; create table sitecount as  select distinct "&study" as study,a.STNAME,nbpat, 
sum(case when CRFStat LIKE '%Complete%' then 1 else 0 end)  as complete "Number of completed forms", 
sum(case when CRFStat LIKE '%Complete%' then 1 else 0 end) / ( sum(case when CRFStat LIKE '%Complete%' then 1 else 0 end) 
+sum(case when CRFStat LIKE '%Due%' then 1 else 0 end)
+sum(case when CRFStat LIKE '%Incomplete%' then 1 else 0 end) ) as PRcomplete "% of completed forms" format=percent.,

sum(case when CRFStat LIKE '%Incomplete%' then 1 else 0 end)  as incomplete "Number of Incomplete forms", 

sum(case when CRFStat LIKE '%Incomplete%' then 1 else 0 end) / ( sum(case when CRFStat LIKE '%Incomplete%' then 1 else 0 end) 
+sum(case when CRFStat LIKE '%Due%' then 1 else 0 end)
+sum(case when CRFStat LIKE '%Incomplete%' then 1 else 0 end) ) as PRincomplete "% of incompleted forms" format=percent.,



sum(case when CRFStat LIKE '%Due%' then 1 else 0 end) as DUE,
sum(case when CRFStat LIKE '%Due%' then 1 else 0 end) / ( sum(case when CRFStat LIKE '%Complete%' then 1 else 0 end) 
+sum(case when CRFStat LIKE '%Due%' then 1 else 0 end)
+sum(case when CRFStat LIKE '%Incomplete%' then 1 else 0 end) ) as PRDUE "% of DUE forms" format=percent.
from Formstatus a
left join nbpat b on a.STNAME=b.STNAME

group by a.STNAME,study ORDER BY STNO ;quit;

 /* 3 types de macro variable */
%let daterep=%sysfunc(today(),date8.);
%let datetemp=%sysfunc(today(),yymmdd9.);
data _null_;test=strip("&datetemp");datefileL=tranwrd(test,"-",".");call symputx('datefile',datefileL);run;

%macro CreatFolder(dossier);
option NOXWAIT;	 /* pecifies that the command processor automatically returns to the SAS session after the specified command is executed. You do not have to type EXIT. */
x mkdir "&dossier.";  /* créer le dossier en commande dos */
%mend;
%CreatFolder(&pathout\DOSSIER\&datefile.);
ods excel file="&pathout\DOSSIER\&datefile.\&datefile. fichier pour moussa.xlsx" ;
proc print data=sitecount label noobs;run;
ods excel close;
