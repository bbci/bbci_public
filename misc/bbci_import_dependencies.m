function download_success = bbci_import_dependencies(lib)
% IMPORT_IMPORT_DEPENDENCIES(LIB) - imports code from other toolboxes
%
% Other toolboxes might be published on copy-left licences such as GPL.
% Moreover, we don't want to publish the same code twice.
% Therefore, several important (but not essential!) functionalities and
% methods were  not included in the BBCI toolbox, which is under MIT
% license. This script downloads the corresponding code and copies it into
% the folder 'external' and genereates corresponding subfolders.
%
% If the subfolder already exists, then the import fails with a warning.
%
%
%Usage:
%bbci_import_dependencies() %import everything
%bbci_import_dependencies('fastica) %import only fastICA
%
%
% JohannesHoehne 04/2015

if nargin == 0
    lib = '*';
end
fprintf('Trying to import dependencies\n');
global BTB
ext_folder = fullfile(BTB.Dir, 'external');
download_success = 0;
switch lower(lib)
    case '*'
        disp('checking dependencies and downloading external sources if necessary...')
        all_libs = {'fastica', 'ssd+spoc', 'mara'};        
        for kk = 1:length(all_libs)
            %recursive loop ^^
            success = bbci_import_dependencies(all_libs{kk});
        end
    case 'ssd+spoc'        
        this_folder = fullfile(ext_folder, lower(lib));
        if ~exist(this_folder, 'dir') %check if already existing
            try %download and unzip
                download_success = 0;
                this_zipfile = 'https://github.com/svendaehne/matlab_SPoC/archive/master.zip';
                disp(sprintf(['\n\n\n...Downloading ' lower(lib) ' from github']))
                download_success = try_download_unzip(this_zipfile, ext_folder);
                movefile(fullfile(ext_folder, 'matlab_SPoC-master'), this_folder)
            catch
                if download_success
                    error(['renaming did not work, please rename ''matlab_SPoC-master'' to ''' lower(lib) ''' manually.']);
                else
                    warning(['automatic download and unzip unsuccessful for ' lower(lib) '.'])
                    fprintf(['Likely reason: \n(A) Matlab does not have the permission to write files into the folder. \n(B) no online access.\n\n Possible solution is to start Matlab as root. \n\nFor manual download:\n\n (1) download the zip-file: \n' this_zipfile '\n\n (2) unzip to ''' this_folder '''\n']);
                end
            end
        else
            warning(['Could not import ' lib ', because the folder external/' lower(lib) 'already existed! Please delete this folder to refresh the import.'])
        end
    case 'fastica'
        this_folder = fullfile(ext_folder, lower(lib));
        if ~exist(this_folder, 'dir') 
            %download only if folder is not existing yet
            try %download and unzip
                download_success = 0;
                this_zipfile = 'http://research.ics.aalto.fi/ica/fastica/code/FastICA_2.5.zip';
                disp(sprintf(['\n\n\n...Downloading ' lower(lib) ' from http://research.ics.aalto.fi']))
                download_success = try_download_unzip(this_zipfile, ext_folder);
                movefile(fullfile(ext_folder, 'FastICA_25'), this_folder)
            catch
                if download_success
                    error(['renaming did not work, please rename ''FastICA_2.5'' to ''' lower(lib) ''' manually.']);
                else
                    warning(['automatic download and unzip unsuccessful for ' lower(lib) '.'])
                    fprintf(['Likely reason: \n(A) Matlab does not have the permission to write files into the folder. \n(B) no online access.\n\n Possible solution is to start Matlab as root. \n\nFor manual download:\n\n (1) download the zip-file: \n' this_zipfile '\n\n (2) unzip to ''' this_folder '''\n']);
                    
                end
            end
        else
            warning(['Could not import ' lib ', because the folder external/' lower(lib) 'already existed! Please delete this folder to refresh the import.'])
        end
    case 'mara'
        this_folder = fullfile(ext_folder, lower(lib));
           if ~exist(this_folder, 'dir') 
            %download only if folder is not existing yet
            try %download and unzip
                download_success = 0;
                this_zipfile = 'https://github.com/irenne/MARA/archive/master.zip';
                zip_folder_name = 'MARA-master';
                disp(sprintf(['\n\n\n...Downloading ' lower(lib) ' from ' this_zipfile]))
                download_success = try_download_unzip(this_zipfile, ext_folder);
                movefile(fullfile(ext_folder, zip_folder_name), this_folder)
            catch
                if download_success
                    error(['renaming did not work, please rename ' zip_folder_name ' to ''' lower(lib) ''' manually.']);
                else
                    warning(['automatic download and unzip unsuccessful for ' lower(lib) '.'])
                    fprintf(['Likely reason: \n(A) Matlab does not have the permission to write files into the folder. \n(B) no online access.\n\n Possible solution is to start Matlab as root. \n\nFor manual download:\n\n (1) download the zip-file: \n' this_zipfile '\n\n (2) unzip to ''' this_folder '''\n']);                    
                end
            end
        else
            warning(['Could not import ' lib ', because the folder external/' lower(lib) 'already existed! Please delete this folder to refresh the import.'])
        end

    case 'plot2svg'
        this_folder = fullfile(ext_folder, lower(lib));
           if ~exist(this_folder, 'dir') 
            %download only if folder is not existing yet
            try %download and unzip
                download_success = 0;
                this_zipfile = 'https://github.com/jschwizer99/plot2svg/archive/master.zip';
                disp(sprintf(['\n\n\n...Downloading ' lower(lib) ' from https://github.com/jschwizer99/']))
                download_success = try_download_unzip(this_zipfile, ext_folder);
                movefile(fullfile(ext_folder, 'plot2svg-master'), this_folder)
            catch
                if download_success
                    error(['renaming did not work, please rename ''plot2svg-master'' to ''' lower(lib) ''' manually.']);
                else
                    warning(['automatic download and unzip unsuccessful for ' lower(lib) '.'])
                    fprintf(['Likely reason: \n(A) Matlab does not have the permission to write files into the folder. \n(B) no online access.\n\n Possible solution is to start Matlab as root. \n\nFor manual download:\n\n (1) download the zip-file: \n' this_zipfile '\n\n (2) unzip to ''' this_folder '''\n']);                    
                end
            end
        else
            warning(['Could not import ' lib ', because the folder external/' lower(lib) 'already existed! Please delete this folder to refresh the import.'])
        end

    otherwise
        error('dependency not specified')
end
end



function success = try_download_unzip(this_zipfile, ext_folder)
% downloads a zip file and extracts it into a specific folder. 
success = 0;
try
%%easy way: unzip file from url to folder 
%   this call may cause a corrupt folder, if user has now rights, therefore
%   it is implemented in a less conveniert way...
%     unzip(this_zipfile, ext_folder) 
%        
% catch

% less convenient: (1) download file, (2) unzip (3) delete zip
%     (1) download file
    tmp_file = fullfile([ext_folder '/temp_download.zip']);   
    urlwrite(this_zipfile, tmp_file);
%     (2) unzip (OS-dependent)
    if isunix
        [status,cmdout] = system(['unzip ' tmp_file ' -d ' ext_folder]);
    else
        unzip(fullfile([ext_folder '/temp_download.zip']), ext_folder);
    end
%     (3) delete zip
    delete(fullfile([ext_folder '/temp_download.zip'])); %delete temporary download file
    success = 1;
end

end

