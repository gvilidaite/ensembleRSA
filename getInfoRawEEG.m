function output = gv_getInfoRawEEG(targetpath, var, cond, trial)

% This function returns any variable from the exported xDiva Matlab files
% (e.g. Raw_cXXX_tYYY.mat). Input:
%       - targetpath - where the .mat files are stored (usually a folder for
%   that particular subject. Give as string
%       - var - the variable in the file that needs to be extracted (e.g.
%       RawTrial). Give as string
%       - cond - condition number of the file (XXX in the file name). Give
%       as number
%       - trial - trial number of the file (YYY in the file name). Give
%       as number

% This function does not have the capability to return information from all
% conditions and trials of the subject on purpose, as that would create a
% massive variable. This function is meant to be used in a loop.

% 14th May 2018 Greta Vilidaite


cd(targetpath)

condstring = sprintf('%03d',cond);
trialstring = sprintf('%03d',trial);

file = load(strcat(targetpath, 'Raw_c', condstring, '_t',...
    trialstring,'.mat'));
    
var = strcat('file.',var);

output = eval(var);

clear file

end