% Ensemble Searchlight electrode analysis, which analyses each electrode
% separately (as in the Mat
% GV 18th May 2018

% So far only does whole timecourse classification

<<<<<<< HEAD
% close all
=======
close all
>>>>>>> 3f08fc5bd36ffebe4840513c37ed1ede6d815f01
clear all

% SOME FLAGS TO SET:
doSearchlight = 0; % 1 = do RSA using the following flags; 0 = just load in the specified file and plot stuff


outputFile = 'SearchlightEnsemble';
% this is the file that RSA results will be saved in;
% or if RSA is not being done, this is the file that will be loaded in and
% plotted, completing the filename using the below flags (the file name is
% autocmpelteled based on them)

averagetrials = -1; % how many trials to average over during classifyEEG. Set to negative numebr to not do averaging

whichlabels = 1; % 1 = object category labels; 2 = exemplar labels

timepoints = 1;
% 1 = all timepoints and all electrodes;
% 2 = in moving windows (number of which specified below). Time windows are separated using gv_make_sliding_windows.m

NTimeWindows = 10; % number of time windows to separate the data into if
% doing time window analysis. Each time window starts in the middle of the
% previous one. 


<<<<<<< HEAD
datapath = '/Users/babylab/Greta/2015_Ensembles_data/';
=======
datapath = '/Users/babylab/Greta/2015_Ensembles_data/'; % point this to the folder containing the prepared matlab files
>>>>>>> 3f08fc5bd36ffebe4840513c37ed1ede6d815f01
cd(datapath);


% Naming the output file properly and adding some information:

if (whichlabels == 1)
    namestr1 = '_categ';
    RSAinfo.labels = 'category level';
else
    namestr1 = '_exemp';
    RSAinfo.labels = 'exemplar level';
end

if (timepoints == 1)
    namestr2 = '_alltimepoints';
    RSAinfo.timepoins = 'all timepoints';
elseif (timepoints == 2)
    namestr2 = strcat('_windowsof', num2str(NTimeWindows));
    RSAinfo.timepoins = 'Sliding time windows, separated by gv_make_sliding_windows';
end

outputFile = strcat(outputFile, namestr1, namestr2,'.mat'); % renaming the file properly



files = dir('*_data4RSA.mat');


% Seachlight electrode analysis -------------------------------------------
if doSearchlight == 1
    
    % setting up some empty cell arrays to store data in:
    predY = {}; % _s for searchlight
    pVal = {};
    classifierInfo = {};

    for n = 1:length(files)
        currentfilename = files(n).name;
        
        disp(strcat('##### Classifying EEG data for ', currentfilename,' #####'))
        
        currentfile = load(currentfilename); % category labels (as opposed to

        if whichlabels == 1 % object category classification
           currentY = currentfile.labelsByCond; % all category labels in a single vector
        elseif whichlabels == 2 % object exemplar classification
           currentY = currentfile.labelsByExemp; % all exemplar labels in a single vector
        end
        
       
        % Doing searchlight RSA
        
        for elec = 1:size(currentfile.EEGdata_downsampled,2) % loop over the electrode dimension
            if (timepoints == 1) % Whole trial, electrode x trial data (timepoints averaged)
                currentX = squeeze(currentfile.EEGdata_downsampled(:,elec,:))';
                [currentCM, currentAccuracy, predY{n}, currentpVal{n}, classifierInfo{n}] = classifyEEG(currentX, currentY, 'classify','LDA','averageTrials',averagetrials);
                CM(n,elec,:,:) = currentCM;
                accuracy(n,elec) = currentAccuracy;
            elseif (timepoints == 2)
                [windowedData indexes] = gv_make_sliding_windows(currentfile.EEGdata_downsampled, NTimeWindows, 1);
                windowsforplotting = indexes; % for saving
                for t = 1:NTimeWindows 

                    tempX = windowedData{t};
                    currentX = tempX(:,elec,:);
                    
                    [currentCM, currentAccuracy, predY{n,t}, currentpVal{n,t}, classifierInfo{n,t}] = classifyEEG(currentX, currentY, 'classify','LDA','averageTrials',averagetrials);
                    CM(n,t,elec,:,:) = currentCM;
                    accuracy(n,t,elec) = currentAccuracy; % dims: subject, time-window, electrode
                end
            end
        end
        clear currentfile
    end

if (timepoints == 1)
    save(strcat(datapath, outputFile),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo');
else
    save(strcat(datapath, outputFile),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo','windowsforplotting');
end
 
 
else % if doSearchlight == 0 and if the specified file exists, load in the file
    if ~exist(outputFile)
        error('No such Searchlight file found')
    else
        load(outputFile)
    end
end

% Plotting the confusion matrices -----------------------------------------

accuracy = squeeze(mean(accuracy, 1)); % mean over subjects

<<<<<<< HEAD
figno = 5;
=======
figno = 1;
>>>>>>> 3f08fc5bd36ffebe4840513c37ed1ede6d815f01

if (timepoints == 1) % if all timepoints analysed together

  
    figno = figno+1;
    figure(figno)

    plotOnEgi([accuracy(1:124)';NaN;NaN;NaN;NaN])
    c = colorbar;
    minAll = min(accuracy(1:124)');
    maxAll = max(accuracy(1:124)');
    c.Ticks = [minAll (minAll+maxAll)/2 maxAll];
    c.FontSize = 15;
    set(gca, 'clim', [min(accuracy(1:124)') max(accuracy(1:124)')]);

elseif (timepoints == 2)
    
    figno = figno+1;
    figure(figno)
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    subplotno = ceil(sqrt(size(accuracy,1)));
    
    for t = 1:size(accuracy,1)
        subplot(subplotno,subplotno,t)
        
        AccToPlot = (squeeze(accuracy(t,1:124)))';
        
        plotOnEgi([AccToPlot;NaN;NaN;NaN;NaN])
        c = colorbar;
        minAll = min(AccToPlot);
        maxAll = max(AccToPlot);
        c.Ticks = [minAll (minAll+maxAll)/2 maxAll];
        c.FontSize = 15;
        set(gca, 'clim', [min(AccToPlot) max(AccToPlot)]);
        

        plotname = strcat(num2str((windowsforplotting(t,1)-1).*(1000/105)),'ms -', ' ', num2str((windowsforplotting(t,2)-1).*(1000/105)), 'ms');
        title(plotname)
    
    end
end

