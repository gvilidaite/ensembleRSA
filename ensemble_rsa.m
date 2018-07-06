% Ensemble RSA analysis, pretty much copied from gv_kaneshiro_rsa.m with an
% added bit at the start that combines subject data into a matrix
% GV 18th May 2018

% UPDATE: Changed so that if doing a new RSA analysis (re-doing it) you select EEG
% matlab files using a GUI. Then the script creates or points towards an
% output folder (created automatically) where separate RSA analysis output
% files are created for each individual subject. This is so that the
% analyses do not need to be redone for everyone if more subjects are
% added. If only plotting of the analysis is required, the script finds the
% correct RSA analysis folder (based on the flags set below), averages them
% and plots stuff. - GV 29th June 2018

% So far only does whole timecourse classification

close all
clear all

% SOME FLAGS TO SET:
doRSA = 1; % 1 = do RSA using the following flags; 0 = just load in the specified file and plot stuff



% Add any other information here (e.g. if you used some averaging
% procedures, artefact rejection, etc):
RSAinfo.other = '';


outputEnd = 'RSAensemble'; % leave as is
% this is the first part of the folder name that RSA results will be saved in;
% or if RSA is not being done, this is the folder that will be used to get RSA files and
% plot data, completing the folder name using the below flags (the folder name is
% auto-completed based on them)

averagetrials = -1; % how many trials to average over during classifyEEG. Set to negative numebr to not do averaging

whichlabels = 1; % 1 = object category labels; 2 = exemplar labels

suppress_diag = 0; % 1 = suppress the diagonale in the CM and distances matrices when using exemplar labels. Doesn't do anything in other plots/analyses 

timepoints = 1;
% 1 = all timepoints and all electrodes;
% 2 = in moving windows (number of which specified below). Time windows are separated using gv_make_sliding_windows.m


NTimeWindows = 10; % number of time windows to separate the data into if
% doing time window analysis. Each time window starts in the middle of the
% previous one. 


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

outputFolder = strcat(outputEnd, namestr1, namestr2,'/'); % renaming the folder properly
        

% RSA analysis ------------------------------------------------------------
if doRSA == 1 % if flag set to 1, do the following RSA analysis and save the results into a .mat file
 
        
    % this opens a GUI to add files for analysis:
    file = 1;
    count = 1;
    while any(file)
        [file path] = uigetfile('', 'Choose _data4RSA.mat files to do RSA on. CLick CANCEL when finished');
        fileList{count} = file;
        count = count + 1;
    end
    
    datapath = uigetdir('Point to the directory where you want the RSA output folder to be')

    if ~exist(strcat(datapath,outputFolder)) % if output folder for that type of analysis does not exist, create it
        mkdir(outputFolder)
    end

    % setting up some empty cell arrays to store data in:
    predY = {};
    pVal = {};
    classifierInfo = {};

    for n = 1:(length(fileList)-1) % go  through fileList but ignore the last cell because it's always just a zero
        currentfilename = fileList{n};
        
        outputFileNameStart = currentfilename(1:(end-13)); % this parses the filename string and only keeps the subject number/initials
        disp(strcat('##### Classifying EEG data for ', currentfilename,' #####'))
        
        currentfile = load(strcat(datapath,'/',currentfilename)); % category labels (as opposed to

        if whichlabels == 1 % object category classification
           currentY = currentfile.labelsByCond; % all category labels in a single vector
        elseif whichlabels == 2 % object exemplar classification
           currentY = currentfile.labelsByExemp; % all exemplar labels in a single vector
        end
        
       
        
        % Doing RSA
        if (timepoints == 1) % Whole trial, electrode x timepoint x trial data
            currentX = currentfile.EEGdata_downsampled;

            [CM, accuracy, predY{n}, currentpVal{n}, classifierInfo{n}] = classifyEEG(currentX, currentY, 'classify','LDA','averageTrials',averagetrials);

        elseif (timepoints == 2)
            [windowedData indexes] = gv_make_sliding_windows(currentfile.EEGdata_downsampled, NTimeWindows, 1);
            windowsforplotting = indexes; % for saving
            for t = 1:NTimeWindows 
                
                currentX = windowedData{t};
                
                [currentCM, currentAccuracy, predY{n,t}, currentpVal{n,t}, classifierInfo{n,t}] = classifyEEG(currentX, currentY, 'classify','LDA','averageTrials',averagetrials);
                CM(t,:,:) = currentCM;
                accuracy(t) = currentAccuracy;
            end
        end
        clear currentfile


        if (timepoints == 1)
            save(strcat(datapath, outputFolder,outputFileNameStart,'.mat'),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo');
        else
            save(strcat(datapath, outputFolder,outputFileNameStart,'.mat'),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo','windowsforplotting');
        end
    end
    
    for n = 1:(length(fileList)-1) % go  through fileList but ignore the last cell because it's always just a zero
        currentfilename = fileList{n};
        % load in the files
        load(strcat(datapath, outputFolder,outputFileNameStart,'.mat'))
        if (timepoints == 1)
            allCM(n,:,:) = CM;
            allAccuracy(n) = accuracy;
        else
            allCM(n,:,:,:) = CM;
            allAccuracy(n,:) = accuracy;
        end
    end

else % if doRSA is NOT 1
    datapath = uigetdir('Point to the folder CONTAINING the RSA output folders');
    
    RSApath = strcat(datapath,'/',outputFolder);
    
    RSAfiles = dir(strcat(RSApath,'*.mat'))
    
    for n = 1:size(RSAfiles,1)
        load(strcat(RSApath,RSAfiles(n).name))
        
        if (timepoints == 1)
            allCM(n,:,:) = CM;
            allAccuracy(n) = accuracy;
        else
            allCM(n,:,:,:) = CM;
            allAccuracy(n,:) = accuracy;
        end
    end
end

% Plotting the confusion matrices -----------------------------------------

grandCM = squeeze(mean(allCM,1)); % mean over subjects
grandCM = grandCM;

if whichlabels == 1
    axislabels = {'HB', 'HF', 'AB', 'AF', 'IN', 'IA'};
else
    for l = 1:length(grandCM)
        axislabels{l} = num2str(l);
    end
end

figno = 0;

if (timepoints == 1) % if all timepoints analysed together
    RDM = computeRDM(grandCM);
    
    if (whichlabels == 2)&&(suppress_diag == 1)
        grandCM = grandCM - diag(diag(grandCM)); % a fudge to replace the diagonale with zeros if looking at exemplar level classification
    end
    
    figno = figno+1;
    figure(figno)

    axis('square')
    plotMatrix(grandCM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0)
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    figno = figno+1;
    figure(figno)
    axis('square')
    plotMatrix(RDM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0)
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    if whichlabels == 1
        figure(3)
        axis('square')

        plotMDS(RDM, 'nodeLabels', axislabels, 'xLim', [-0.35, 0.35], 'yLim', [-0.35, 0.35])
    end
    
else % if time analysed in windows or each timepoint separately 
    figno = figno+1;
    figure(figno)
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    
    subplotno = ceil(sqrt(size(grandCM,1)));
    for m = 1:size(grandCM,1)
        subplot(subplotno,subplotno,m)


        axis('square')
        plotCM = squeeze(grandCM(m,:,:));

        if (whichlabels == 2)&&(suppress_diag == 1)
            plotCM = plotCM - diag(diag(plotCM)); % a fudge to replace the diagonale with zeros if looking at exemplar level classification
        end
        
        plotMatrix(plotCM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0);
        

        plotname = strcat(num2str((windowsforplotting(m,1)-1).*(1000/105)),'ms -', ' ', num2str((windowsforplotting(m,2)-1).*(1000/105)), 'ms');

        title(plotname)
    end
    
    figno = figno+1;
    figure(figno) % plotting the distance matrices
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    
    if (timepoints == 2)
        for m = 1:size(grandCM,1)
            subplot(subplotno,subplotno,m)
            axis('square')
            RDM = computeRDM(squeeze(grandCM(m,:,:)));
            plotMatrix(RDM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0);
            plotname = strcat(num2str((windowsforplotting(m,1)-1).*(1000/105)),'ms -', ' ', num2str((windowsforplotting(m,2)-1).*(1000/105)), 'ms');
            title(plotname)
        end
    end
    
figno = figno+1;
figure(figno)
    if whichlabels == 1
        for m = 1:size(grandCM,1)

            % Enlarge figure to full screen.
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
            
            subplot(subplotno,subplotno,m)
            axis('square')
            RDM = computeRDM(squeeze(grandCM(m,:,:)));
            plotMDS(RDM, 'nodeLabels', axislabels, 'xLim', [-0.35, 0.35], 'yLim', [-0.35, 0.35])
            
            if (timepoints == 2)
                plotname = strcat(num2str((windowsforplotting(m,1)-1).*(1000/105)),'ms -', ' ', num2str((windowsforplotting(m,2)-1).*(1000/105)), 'ms');
            else
                plotname = strcat(num2str(m*16-16),'ms');
            end
            title(plotname)
        end
    end
end


figno = figno+1;
    figure(figno)
    

if (timepoints == 1)
    disp(strcat('Overall accuracy: ', num2str(mean(accuracy).*100)))
else
    disp(strcat('Overall accuracy: ', num2str(mean(accuracy).*100)))
end
