
%global git_macro_version git_macro_version_date;
%let git_macro_version = 0.0.0;
%let git_macro_version_date = 07/07/2020;

%if not(%symexist(dir_path) and %symexist(local_folder)) %then %do;%put ERROR: Macros SBE: la macrovariable  "dir_path" et "local_folder" doit �tre d�clar�e; %end; 
%else %do;  
%include "&dir_path/&local_folder./PROG/1 - Importation.sas";	
%end; 

