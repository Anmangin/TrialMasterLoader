
/* ---------------------------------------------- Programme de lancement --------------------------------------------- ;
date de création/MAJ : 08/2023 par Anthony Mangin
*/


*------------Liste des variables a modifier ---------------------;
%let path=\\nas-01\SBE\04 - Informaticiens\Codes_SAS\SAS - TM\STANDARD\EXEMPLE;

*------------------ ne rien toucher après ici ---------------------;


%let pathin=&path\IN;*a adatper a l'étude;
%let pathout=&path\OUT;*a adatper a l'étude;




%include "&path\PROG\1 - Importation.sas";
	%include "&path\PROG\2 - Relance.sas";
    %include "&path\PROG\3 - Calcul perso.sas";
   %include "&path\PROG\4 - Imprimer relance.sas";
