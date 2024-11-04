

data formsToCheck;
    infile datalines dlm=','; /* Spécifier la virgule comme délimiteur */
    length text $50 type $20; /* Définir la longueur des variables */
    
    input text $ type $; /* Lire les valeurs pour text et type */
    datalines;
3months,Follow-up
patient information,Inclusion
randomization,Inclusion
registration,Inclusion
enrollm,Inclusion
adverse,AE
SAE,AE
recist,Recist
progression,Progression
relapse,Progression
follow,Follow-up
end of study,End of study
death,Death
baseline,Baseline
assessment,Baseline
after end of treatment,Follow-up
end of induction,Evaluation
end of consolidation,Evaluation
mid induction,Evaluation
evaluation,Evaluation
cycle,Treatment
treatment,Treatment
traite,Treatment
surgery,Treatment
consolidation,Treatment
screening,Baseline
week,Treatment
w?d1,Treatment
radiotherapy,Treatment
maintenance,Treatment
neo-adjuvant,Treatment
ae,AE
FU,Follow-up
;
run;

%macro generate_html(folder);


data Relance_form;set  formstatus; if ( nbq=0 or nbq=. and CRFStat="Complete") then delete ;run;

data _null_;
set formsToCheck end=endform;
call symputx('text'||left(_N_),text);
call symputx('type'||left(_N_),type);
if endform then call symputx('nbform',_N_);
run;
data Relance_form;
set Relance_form;
format VISITN $50.;
%do P=1 %to &nbform;
if find(upcase(CRFName),upcase("&&text&P")) or find(upcase(VISITN),upcase("&&text&P")) then Mytype="&&type&P";
%end;
run;


proc sql noprint; create table Relance_site as select distinct STNAME from Relance_form;quit;
data _null_;
set Relance_site end=endsite;
call symputx('STNAME'||left(_N_),STNAME);
if endsite then call symputx('nbsite',_N_);
run;
%do i=1 %to &nbsite;
	%put Creation des relance pour ;

	proc sql noprint; create table Relance_PAT as select distinct SUBJID from Relance_form where STNAME="&&STNAME&i" ORDER BY SUBJID ;quit;

	data _null_;
	set Relance_PAT end=endpat;
	call symputx('SUBJID'||left(_N_),SUBJID);
	if endpat then call symputx('nbpat',_N_);
	run;

	ods html path="&folder" body="&&stname&i...html";

	%do J=1 %to &nbpat;

		%Print_by_Pat(&&SUBJID&J);


	%end;

	ods html close;
%end;

%mend;

%macro Print_by_Pat(patient);

title " PATIENT &patient";
proc print data=Relance_form label noobs;
var SUBJID VISITN CRFName CRFStat VISDAT nbq;
where SUBJID=&patient;

run;

proc print data=Dcr label noobs;
var SUBJID VISITN CRFName  QuestTxt  responseTXT CURSTATE Comment;
where SUBJID="&patient";

run;

%mend;
