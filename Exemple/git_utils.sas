/*
* Macro de chargement du git, a importer manuellement
*/
%macro install_git(dir_path /* chemin (absolu) vers l'espace de travail local */, 
                   git_url=https://github.com/DanChaltiel/macro_sas.git /* repository git a charger */, 
                   version=master /*version: release, tag, branch ou hash*/,
                   local_folder=git_macro /* nom du dossier a creer pour contenir le clone*/);

%let git_macro_path = &dir_path\&local_folder;
filename git_path "&git_macro_path";
%if %sysfunc(fexist(git_path)) %then %do; 
    %put NOTE: Le dossier "&local_folder" existe deja dans le repertoire &dir_path.;
    %put NOTE- Les macros ne seront pas mises a jour depuis GitHub.;
    %put NOTE- Supprimer le dossier "&local_folder" pour recuperer la derniere version.;
%end; 
%else %do;  
    %put NOTE: Clonage du git des macros SBE;
    data _null_;
        rc = gitfn_clone("&git_url", "&git_macro_path");
        put rc=;
    run;
    %if &version ne master %then %do;
        data _null_;
            rc = gitfn_co_branch("&git_macro_path", "&version");
            put rc=;
        run;
        %put NOTE: Clonage termine, version "&version" installee;
    %end;
    %else %do;
        %put NOTE: Clonage termine, derniere version installee;
    %end;
%end; 

%include "&dir_path\&local_folder\_autoexec.sas";
%put NOTE: Chargement des macros depuis Git, version &git_macro_version du &git_macro_version_date;
%mend;


%macro install_github(dir_path /* chemin (absolu) vers l'espace de travail local */, 
                      repo=DanChaltiel/macro_sas /* repository github (Username/Repo) a charger */, 
                      version=master /*version: release, tag, branch ou hash*/,
                      local_folder=git_macro /* nom du dossier a creer pour contenir le clone*/);
%let git_url = https://github.com/&repo.git;
%install_git(dir_path=&dir_path, git_url=&git_url, version=&version, local_folder=&local_folder);
%mend;
