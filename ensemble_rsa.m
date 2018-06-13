% Ensemble RSA analysis, pretty much copied from gv_kaneshiro_rsa.m with an
% added bit at the start that combines subject data into a matrix
% GV 18th May 2018

% So far only does whole timecourse classification

close all
clear all

% SOME FLAGS TO SET:
doRSA = 0; % 1 = do RSA using the following flags; 0 = just load in the specified file and plot stuff


outputFile = 'RSAensemble';
% this is the file that RSA results will be saved in;
% or if RSA is not being done, this is the file that will be loaded in and
% plotted, completing the filename using the below flags (the file name is
% autocmpelteled based on them)

averagetrials = -1; % how many trials to average over during classifyEEG. Set to negative numebr to not do averaging

whichlabels = 2; % 1 = object category labels; 2 = exemplar labels

suppress_diag = 0; % 1 = suppress the diagonale in the CM and distances matrices when using exemplar labels. Doesn't do anything in other plots/analyses 

timepoints = 1;
% 1 = all timepoints and all electrodes;
% 2 = in moving windows (number of which specified below). Time windows are separated using gv_make_sliding_windows.m


NTimeWindows = 10; % number of time windows to separate the data into if
% doing time window analysis. Each time window starts in the middle of the
% previous one. 


datapath = '/Users/babylab/Greta/2015_Ensembles_data/';
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


% RSA analysis ------------------------------------------------------------
if doRSA == 1 % if flag set to 1, do the following RSA analysis and save the results into a .mat fil
    
    % setting up some empty cell arrays to store data in:
    predY = {};
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
        
       
        
        % Doing RSA
        if (timepoints == 1) % Whole trial, electrode x timepoint x trial data
            currentX = currentfile.EEGdata_downsampled;
            [currentCM, currentAccuracy, predY{n}, currentpVal{n}, classifierInfo{n}] = classifyEEG(currentX, currentY, 'classify','LDA','averageTrials',averagetrials);
            CM(n,:,:) = currentCM;
            accuracy(n) = currentAccuracy;
        elseif (timepoints == 2)
            [windowedData indexes] = gv_make_sliding_windows(currentfile.EEGdata_downsampled, NTimeWindows, 1);
            windowsforplotting = indexes; % for saving
            for t = 1:NTimeWindows 
                
                currentX = windowedData{t};
                
                [currentCM, currentAccuracy, predY{n,t}, currentpVal{n,t}, classifierInfo{n,t}] = classifyEEG(currentX, currentY, 'classify','LDA','averageTrials',averagetrials);
                CM(n,t,:,:) = currentCM;
                accuracy(n,t) = currentAccuracy;
            end
        end
        clear currentfile
    end
        


if (timepoints == 1)
    save(strcat(datapath, outputFile),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo');
else
    save(strcat(datapath, outputFile),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo','windowsforplotting');
end
 
 
else % if doRSA == 0 and if the specified file exists, load in the file
    if ~exist(outputFile)
        error('No such RSA file found')
    else
        load(outputFile)
    end
end




% Plotting the confusion matrices -----------------------------------------

grandCM = squeeze(mean(CM,1)); % mean over subjects
axislabels = {'HB', 'HF', 'AB', 'AF', 'IN', 'IA'};



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
