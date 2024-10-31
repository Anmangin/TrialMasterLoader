** merge des données dans une table resume;
	
** merge des données dans une table resume;
	/* a cette étape, vous avec 2 tables dans la work : formstatus et DCR.

on va commencer par ajouter a formstatus TOUTES les dates qui nous seront utile pour calculer le statut manquant.
/* ETAPE 1 AJOUT DES DATE DANS LA Fiche formstatus
*/

/*table temporaire pour chopper les patients décédé dans FU */
data fu_dth;
set db.FU;
where FUCS=2;
run;
proc sort nodupkey; by SUBJID;run;


/* ----------------------- AJOUT DES VARIABLES A FORMSTATUS --------------------- */


proc sql noprint; 
create table Formstatus2 
as select 
a.*, 
b.ENROLLID,
b.ENROLLDT,
c.EOSDT /* fin d'étude*/ 
from 
Formstatus a 
left join db.Res b on a.SUBJID=b.SUBJID										  
left join  db.Eos c on a.SUBJID=c.SUBJID
where a.SUBJID NE "";
quit;


/* si vous ne savez pas faire de SQL voici le code en data set



data F04_res;set db.F04_res;keep  SUBJID ENROLLID ENROLLDT ; run;
proc sort; by SUBJID;run;

data F23_eos;set db.F23_eos;keep  SUBJID ENROLLID EOSDT ; run;
proc sort; by SUBJID;run;


data Formstatus2;
merge Formstatus F04_res F23_eos fu_dth;
by SUBJID;
run;


/* ----------------------- calcul de DEXPECT --------------------- */

data Formstatus;
set Formstatus2;
if VISDAT=. then VISDAT=VSDT;
if VISDAT=. then VISDAT=VSDT;
format DEXPECT DDMMYY10.;
/* pour les visite de registration et de baseline, on attend les fiches au moment de l'enregistrement */
if 	 find(VISITN,"egistration")>0 or find(VISITN,"Baseline")>0  then DEXPECT=ENROLLDT;

/* pour les visite de cycle, je cacule 1 2 3 pour cycle 1 cycle 2 cycle 3, je rajoute 30 jours par ce chiffre ca me fait le nombre de jour depuis l'inclusion.
aussi je rajoute la date d'enregistrement et j'obtien ma date attendu.*/
if  find(VISITN,"Cycle") then DEXPECT=(input(VISIT1,3.)-2) * 30  + ENROLLDT ;


format  ENDTRT DDMMYY10.;
run;

/* ----------------------- creation d'un label pour plus de visibilité --------------------- */
proc format;
value $status
"No Data"=" "
"Complete"="OK"
"Incomplete"="INC."
"Due"="Due";
run;


/* ----------------------- calcul des fiches manquantes --------------------- */

data Formstatus;
set Formstatus;
datsas=today();
if EOSDT NE . then datsas=EOSDT;
else if FUDT NE . then datsas=FUDT;



format CRFStat status.;
FN=substr(CRFName,2,2);
label SUBJID= "Patient Number";
format datsas ddmmyy10.;
format OVERDAT DDMMYY10.;
if   CRFStat="No Data" then do;
 if CRFName="Add visit" or SUBJID =. then delete;
else if DEXPECT<datsas and DEXPECT NE .  then CRFStat="Due" ;
end;
run;

/* ----------------------- creation/arrangement d'une variable pour trier les fiches dans l'ordre --------------------- */
data formstatus;
set formstatus;

else if VISIT1=. then  VISIT1="998";
VISIT1_N=input(VISIT1,5.);
FN_N=input(fn,2.);

if FN_N<5 then VISIT1="0";
else if find(VISITN,"Baseline")>0 then VISIT1="1";
if VISITN="Hospitalization"	then delete;
VISIT1_N=input(VISIT1,5.);
run;

proc sort data=formstatus sortseq=linguistic (numeric_collation=on) ; 
by SUBJID  VISIT1 FN CRFInsNo;  ;run;

