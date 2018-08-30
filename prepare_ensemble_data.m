% This script extracts the EEG data, category and exemplar labels from the
% Raw .mat files and combines them into a single file for each subject

% Greta Vilidaite, 11th May 2018


% Note: The RSA toolbox expects an EEG data frame X and a vector of stimulus labels
% Y. X can be a 3D matrix (electrodes x time x trials) or a 2D matrix
% (features x trials).

close all
clear all

%subjects = {'ASG1','ASG2','AY1','AY2','nl-0043_p1','nl-0045_p1','nl-0046_p1','nl-0047_p1','nl-0048_p1','PJK1','PJK2','VV1','VV2','WM'};

% 'nl-0014','nl-0034','nl-0043','nl-0045','nl-0046','nl-0047','nl-0048','nl-1671','nl-1672',

subjects = {'nl-1676','nl-1677','nl-1678','nl-1681','nl-1684','nl-1685','nl-1686'};

% EEGpath = '~/Greta/2015_Ensembles_data/EEG_files/';
EEGpath = '~/Greta/2018_Ensemble_greyscale_data/EEG_files/';

cd(EEGpath);

downsampling_factor = 4;

% find and open all Run Time Segment files and put them in one matrix:

for s = 1:length(subjects)
    s
    allSeg = dir(strcat(subjects{s},'/RTSeg*')); % get info (names) of all segment files

    count = 0;
    for n = 1:length(allSeg)

        listSegs{n} = allSeg(n).name;
        
        load(strcat(subjects{s},'/',listSegs{n}));

        if ~isempty(TimeLine) % checks that there is some information in there
            count = count + 1;
            % adding each structure's info onto the end of our vectors
            if count == 1
                ind_start = 1;
                ind_end = length(TimeLine);
            else
                ind_start = ind_end + 1;
                ind_end = length(TimeLine) + ind_start - 1;
            end

            currentSeg = extractfield(TimeLine, 'cndNmb');
            condNs(ind_start:ind_end) = currentSeg;
            currentSeg = extractfield(TimeLine, 'trlNmb');
            trialNs(ind_start:ind_end) = currentSeg;
        end
    end


    exempNs = mod(trialNs,6)+1; % calculating the exemplar level labels from trial numbers;

    exempcodeSeg = (condNs-1)*6+exempNs; % giving each exemplar a unique number (1-36)

    count = 0;
    for c = 1:6 % for each condition

        curExemps = exempcodeSeg((condNs==c)); % retrieving unique exemplar numbers just for this condition
        c
        exempcodeSeg(1:20)
        condNs(1:20)
        curExemps(1:20)
        clear allRaw
        allRaw = dir(strcat(subjects{s},'/Raw_c00',num2str(c),'_t*')); % get info (names) of all segment files

        for t = 1:length(allRaw)
            
            count = count + 1;

            EEG = load(strcat(subjects{s},'/','Raw_c',num2str(c,'%03d'),'_t',num2str(t,'%03d'),'.mat')); % loading the file

            labelsByCond(count) = c;

            labelsByExemp(count) = curExemps(t);

            EEGdata(:,:,count) = EEG.RawTrial;

            for el = 1:130 % for each electrode
                EEGdata_downsampled(:,el,count) = decimate(double(EEG.RawTrial(:,el)), downsampling_factor); % downsampled EEG data
            end    

            clear EEG

        end
    end

    save(strcat('~/Greta/2018_Ensemble_greyscale_data/Matclass_ready_08_2018/',subjects{s},'_data4RSA.mat'), 'EEGdata', 'labelsByCond', 'labelsByExemp', 'EEGdata_downsampled')
end

