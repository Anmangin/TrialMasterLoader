
%let mailtoF=;

%macro getmail(NCT);
%let mailtoF=;
data temp; set contact;where STNO = &NCT and email NE "" ;run;
data _null_; set temp end=endperson; call symputx("email"||left(_N_),email);if endperson then call symputx("nbctmail",_N_);run;

%do ma=1 %to &nbctmail;
%let mailT= %sysfunc(strip(&&email&ma)) ;
%let mailtoF= &mailtoF %str(;) &mailT;
%end;
%suppr(temp);
%mend;

 



%macro HTML_Body_relance(site,nb,Form,queries);




%let background=lightgray;
%let foreground=black;
%let font_face='calibri';




proc template;
   define style Styles.sasref;
   parent=Styles.HTMLBlue;;
replace layoutregion / background  = &background. 
				  foreground  = &foreground 
				  font_face   = &font_face
				   font_size   = 18pt
				   borderstyle=double
					borderwidth = 0.1cm
					just        = c
					verticalalign=top
					margin=2px
					padding=10px
					;
   replace usertext / background  = &background. 
				  foreground  = &foreground 
				  font_face   = &font_face
				   font_size   = 18pt
				   bordertopwidth = 0cm
				    borderleftwidth = 0cm
					borderrightwidth = 0cm
					borderbottomwidth = 0.1cm
					just        = c;
    replace paragraph / background  = &background. 
				  foreground  = steel 
				  font_face   = &font_face
				   font_size   = 24pt
					verticalalign=bottom;

replace body / background  = GRAY82 
				  foreground  = &foreground. 
				  font_face   = &font_face;

   replace branch /   background  = &background. 
				  foreground  = &foreground. 
				  font_face   = &font_face
					margin=0px;  

   replace table / rules       = groups
                    frame       = hsides
                    background  = white
                  cellspacing = 0
                    bordercolor = gray
                    borderwidth = .2cm
 					background  = &background.
				  	foreground  = &foreground. 
					borderwidth = .05cm;
   replace header / 
                    font_size   = 12pt
                    font_face   = &font_face
                    font_weight = medium
					just        = c
 					background  = &background. 
				  	foreground  = &foreground. 
				  	font_face   = &font_face
 					FONT_WEIGHT = bold;  

;
   replace rowheader / 
    				FONT_WEIGHT = bold
                    font_size   = 12pt
                    font_face   = &font_face
                    font_weight = medium
					just        = c
 					background  = &background. 
				  	foreground  = &foreground. 
				  	font_face   = &font_face
					borderwidth = .05cm
                    FONT_WEIGHT = bold;  ;  

;


   replace data   / 
                    font_size   = 12pt
                    font_face   = &font_face
                    cellwidth   = 2 cm
                    just        = c
					borderwidth = 0.1 px
					background  = &background. 
				  	foreground  = &foreground. 
				  	font_face   = &font_face; 

	replace column / just = l 
			background  = &background. 
			foreground  = &foreground. 
			font_face   = &font_face 
borderwidth = .05cm;;

   end;
run;




ods NOPROCTITLE;
ods escapechar="^";
  option orientation=portrait;
  title ;
  footnote;
  ods escapechar="^";

%let Gtitre=just=c fontsize=24pt font_weight=bold verticalalign=middle;
%let titre=just=c fontsize=12pt font_weight=bold verticalalign=middle;
%let mybody=just=l fontsize=12pt  verticalalign=middle;


 ods html path="&pathoutput.\" file="&nb..html" style=Styles.sasref NOGTITLE  nogtitle nogfootnote encoding="wlatin1";;

ods layout start columns=3 rows=3;


ods region column_span=2;
%Corp_Message;


ods region ;

%let datefull=%sysfunc(datetime(),nldatmw.);



%Corp_Signature;



%if &Form %then %do;
ods region column_span=3;
title;
	proc odstext;
p "Tableau des fiches à vide ou avec requêtes"/style={&titre};run;

proc report data=Formstatus nofs spanrows
style(column)=[just=center font=('Arial',10pt) vjust=middle CELLWIDTH=5cm]
style(header)=[font=('Arial',10pt,bold) background=_und_ vjust=middle]
style(report)=[cellpadding=3pt rules=all frame=box];;
column 	SUBJID VISIT1 VISITN CRFName 	links CRFStat nbq;

define SUBJID/group order style=[CELLWIDTH=2cm];
define VISIT1/display noprint order;
define VISITN /group order  style=[CELLWIDTH=8cm];
define CRFName/display noprint;
define links / display;
 compute   links;
 call define(_col_, "URL", links);
 call define(_col_, "style", "style=[color=blue textdecoration=underline");

links=CRFName;

    endcomp;
	label links="form";
	where not (find(CRFStat,"Complete") and nbq<1) and sitec="&site";;
run;

%end;

%if &queries %then %do;
ods region column_span=3;
title;
	proc odstext;
p "Tableau des queries en cours"/style={&titre};run;

proc report data=Dcr  nofs spanrows;
column SUBJID VISITN CRFName links QuestTxt responseTXT Comment ;
define SUBJID/group order style(column)=[cellwidth=3cm];
define VISITN/group order style(column)=[cellwidth=5cm];
define links/display  style(column)=[cellwidth=5cm];

define crfname/display noprint;
DEFINE Comment / display style(column)=[cellwidth=18cm];
 compute   links;
 call define(_col_, "URL", links);
 call define(_col_, "style", "style=[color=blue textdecoration=underline");

links=CRFName;

    endcomp;
where sitec="&site";
run;
%end;
;ods layout END;
	   ods html close;


%mend;



%macro sendmail(site,NB,Form,queries,display);
 %getmail(&nb);
%HTML_Body_relance(&site,&nb.,&Form,&queries);

FILENAME script "&pathoutput\&NB..vbs" encoding="wlatin1";
DATA _NULL_;
FILE script;
PUT "dim objOutlk";
PUT "dim objMail";
PUT "const olMailItem = 0";
PUT "set objOutlk = createobject(""Outlook.Application"")";
PUT "set objMail = objOutlk.createitem(olMailItem)";
PUT "objMail.Cc = ""&CC_mail""";
PUT "objMail.To = ""&mailtoF""";
PUT "objMail.subject = ""[&study] -  demande de réponse pour les queries en cours - &site """;
PUT " Dim fsob ";
PUT "  Dim fichier ";
PUT "  Set fsob = CreateObject(""Scripting.FileSystemObject"") ";
PUT "  Set fichier = fsob.OpenTextFile(""&pathoutput.\&nb..html"", 1) ";
PUT "  chaine = fichier.readAll()	 "; 
PUT "chaine=Replace(chaine,""c paragraph"",""paragraph"")";
PUT "chaine=Replace(chaine,""c layoutregion"",""layoutregion"")";
PUT "chaine=Replace(chaine,""c m layoutregion"",""layoutregion"")";
PUT "chaine=Replace(chaine,""c t layoutregion"",""layoutregion"")";
PUT "objMail.HTMLbody =   chaine ";

PUT "objMail.SaveAs ""&pathoutput.\&NB. Relance &study &datefile. Centre &nb..msg""";
%if &queries %then %do;
PUT "objMail.Display";
%end;

PUT "set objMail = nothing";
PUT "set objOutlk = nothing";
RUN;

;
x  "wscript ""&pathoutput\&NB..vbs"""; 

%mend;


%macro Run_relance(Form=1,queries=1,display=0);

%let pathoutput=&pathout\DOSSIER\&datefile.;
%put NOTE: fichier de sortie : &pathoutput;
%CreatFolder(&pathoutput);


proc sql noprint; create table site_rel as select distinct SITEC, STNO from Formstatus;quit;
data _null_;
set site_rel end=endsite;
call symputx("SITEC"||left(_N_),SITEC);
call symputx("STNO"||left(_N_),STNO);
if endsite then call symputx("nbsite",_N_);
run;
%do i=1 %to &nbsite;
%sendmail(&&SITEC&i,&&STNO&i,&Form,&queries,&display);
%end;
%mend;

