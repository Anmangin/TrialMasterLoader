

%let dir_path = R:\test;
%global path pathin pathout;
%let path=\\nas-01\SBE_ETUDES\MEDEA\8 - DM\SAS;
%include "&dir_path\git_utils.sas";
%let git_url = https://github.com/sbemangin/TrialMasterLoader.git;

/*%let  local_folder=git_macro_V3;*/
%install_git(dir_path=&dir_path, git_url=&git_url, version=e0c495c , local_folder=git_TrialMasterLoader);


%put WARNING: INSTALL_GIT: git_macro_version=&git_macro_version;


%dataLoad(DB=1,note=1,status=1);

option mprint=no;
%CreatableTableRelance;
