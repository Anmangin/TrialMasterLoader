
%Macro ISO_Metrics;

  %if %symexist(pathin) = 0 or %symexist(pathout) = 0 or %symexist(path) = 0 %then %do;
        %put ERROR: Macros SBE : La macrovariable "pathin" (&pathin) , "pathout" (&pathout) et path  &path doivent etre declarees;
    %end;
	  %else %if %sysfunc(libref(DB)) NE 0 %then %do;
        %put ERROR: La libname DB n a pas ete creee;
	    %end;
			  %else %if %sysfunc(libref(NOTE)) NE 0 %then %do;
        %put ERROR: La libname NOTE n a pas ete creee;
	    %end;
			  %else %if %sysfunc(libref(STATUS)) NE 0 %then %do;
        %put ERROR: La libname STATUS n a pas ete creee;
	    %end;
    %else %do;

   
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



%CreatFolder(&pathout\DOSSIER\&datefile.);
ods excel file="&pathout\DOSSIER\&datefile.\&datefile. fichier pour moussa.xlsx" ;
proc print data=sitecount label noobs;run;
ods excel close;
%end;
%mend;
