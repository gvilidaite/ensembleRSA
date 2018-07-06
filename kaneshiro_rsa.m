% First try at recreating Kaneshiro et al 2015 RDMs using data downloaded
% from the link in the article and the RSA analysis package described in
% Wang et al 2017

% NOTE:
% Sampling frequency was 62.5Hz, trial length was 512ms and there were 32
% samples per trial. That means the sampling rate was every 16ms.

% GV 18th May 2018

close all
clear all

% SOME FLAGS TO SET:
doRSA = 0; % 1 = do RSA using the following flags; 0 = just load in the specified file and plot stuff


outputFile = 'RSAresults';
% this is the file that RSA results will be saved in;
% or if RSA is not being done, this is the file that will be loaded in and
% plotted, completing the filename using the below flags (the file name is
% autocmpelteled based on them)


whichlabels = 1; % 1 = object category labels; 2 = exemplar labels


timepoints = 2;
% 1 = all timepoints and all electrodes (using the 2D matrix - X_2D);
% 2 = in moving windows of 6 samples (as in Kaneshiro et al 2015, fig 5);
% 3 = each timepoint separately (2D matrix)



datapath = '~/Greta/RSA/Kaneshiro data/';
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
    RSAinfo.timepoins = 'all timepoints'
elseif (timepoints == 2)
    namestr2 = '_windowsof6';
    RSAinfo.timepoins = '80ms windows, 6 samples each, moving by 4 in each';
elseif (timepoints == 3)
    namestr2 = '_individualtime';
    RSAinfo.timepoins = 'all timepoints classified separately generating individual RDMs';
end

outputFile = strcat(outputFile, namestr1, namestr2,'.mat'); % renaming the file properly



% for time window analysis
timewindows = [1:6; 4:9; 7:12; 10:15; 13:18; 16:21; 19:24; 22:27; 25:30];


%----------

if doRSA == 1 % if flag set to 1, do the following RSA analysis and save the results into a .mat file

    subfiles = dir('S*.mat');


    % Retrieving data for both whole trial classification (no time dimension,
    % just electrode x trial); as well as time windor classification (electrode
    % x time x trial)

    % setting up some empty cell arrays to store data in:
    predY = {};
    pVal = {};
    classifierInfo = {};

    for n = 1:length(subfiles)

        disp(strcat('##### Classifying EEG data for S',num2str(n),' #####'))
        
        currentfilename = subfiles(n).name;
        currentfile = load(currentfilename); % category labels (as opposed to

        if whichlabels == 1 % object category classification
           currentY = currentfile.categoryLabels; % all category labels in a single vector
        elseif whichlabels == 2 % object exemplar classification
           currentY = currentfile.exemplarLabels; % all exemplar labels in a single vector
        end
        
       
        
        % Doing RSA
        if (timepoints == 1) % Whole trial, electrode x trial data (timepoints averaged)
            currentX = currentfile.X_2D; %  2D data (electrodes+timepoints x trial)
            [currentCM, currentAccuracy, predY{n}, currentpVal{n}, classifierInfo{n}] = classifyEEG(currentX, currentY, 'classify','LDA');
            CM(n,:,:) = currentCM;
            accuracy(n) = currentAccuracy;
        elseif (timepoints == 2)
            for t = 1:9 %%%%% MAKE THIS DO MOVING TIME WINDOW ANALYSIS AS IN THE PAPER
                currenttime = timewindows(t,:);
                
                currentX = currentfile.X_3D(:,currenttime,:);
                
                [currentCM, currentAccuracy, predY{n,t}, currentpVal{n,t}, classifierInfo{n,t}] = classifyEEG(currentX, currentY, 'classify','LDA');
                CM(n,t,:,:) = currentCM;
                accuracy(n,t) = currentAccuracy;
            end
        elseif (timepoints == 3)
            for t = 1:currentfile.N
                currentX = currentfile.X_3D(:,t,:);
                
                [currentCM, currentAccuracy, predY{n,t}, currentpVal{n,t}, classifierInfo{n,t}] = classifyEEG(currentX, currentY, 'classify','LDA');
                CM(n,t,:,:) = currentCM;
                accuracy(n,t) = currentAccuracy;
            end
        end
        clear currentfile
    end
        
dgkjsdbfksdbfkjsdfkadfl

    
save(strcat(datapath, outputFile),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo');

else % if doRSA == 0 and if the specified file exists, load in the file
    if ~exist(outputFile)
        error('No such RSA file found')
    else
        load(outputFile)
    end
end



% Plotting the confusion matrices -------------------

grandCM = squeeze(mean(CM,1)); % mean over subjects
axislabels = {'HB', 'HF', 'AB', 'AF', 'FV', 'IO'};

    
if (timepoints == 1) % if all timepoints analysed together

    RDM = computeRDM(grandCM);
    
%     if whichlabels == 2
%         grandCM = grandCM - diag(diag(grandCM)); % a fudge to replace the diagonale with zeros if looking at exemplar level classification
%     end
    figure(1)
    axis('square')
    plotMatrix(grandCM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0)
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    figure(2)
    axis('square')
    plotMatrix(RDM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0)
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    if whichlabels == 1
        figure(3)
        axis('square')
        plotMDS(RDM, 'nodeLabels', axislabels, 'xLim', [-0.35, 0.35], 'yLim', [-0.35, 0.35])
    end
    
    
     % save like this (with the RDMs) if whole trial analysis:
    save(strcat(datapath, outputFile, '_RDM'),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo', 'grandCM', 'RDM');

else % if time analysed in windows or each timepoint separately 
    figure(1)
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    
    subplotno = round(sqrt(size(grandCM,1)));
    for m = 1:size(grandCM,1)
        subplot(subplotno,subplotno,m)
        axis('square')
        plotCM = squeeze(grandCM(m,:,:));

        if whichlabels == 2
            plotCM = plotCM - diag(diag(plotCM)); % a fudge to replace the diagonale with zeros if looking at exemplar level classification
        end
        
        plotMatrix(plotCM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0);
        caxis([0 8])
        
        if (timepoints == 2)
            plotname = strcat(num2str(m*48-48),'ms -', ' ', num2str(m*48-48+80), 'ms');
        else
            plotname = strcat(num2str(m*16-16),'ms');
        end
        title(plotname)
    end
    
    figure(2) % plotting the distance matrices
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    
    if (timepoints == 2) % if sliding time windows of 80ms do this
        for m = 1:size(grandCM,1)
            subplot(subplotno,subplotno,m)
            axis('square')
            RDM = computeRDM(squeeze(grandCM(m,:,:)));
            plotMatrix(RDM, 'axisLabels', axislabels, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0);
            plotname = strcat(num2str(m*48-48),'ms -', ' ', num2str(m*48-48+80), 'ms');
            title(plotname)
        end
    end
    
    if whichlabels == 1 % regardless of what time windows used (if not the whole trial) do this
        for m = 1:size(grandCM,1)
            figure(3)
            % Enlarge figure to full screen:
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
            
            subplot(subplotno,subplotno,m)
            axis('square')
            RDM = computeRDM(squeeze(grandCM(m,:,:)));
            
            %plotMDS(RDM, 'nodeLabels', axislabels, 'xLim', [-0.35, 0.35],
            %'yLim', [-0.35, 0.35]) FIX THIS!!!!!!!!!!!!!
            
            grandRDM(m,:,:) = RDM;
            
            if (timepoints == 2) % plot name according to time windows used
                plotname = strcat(num2str(m*48-48),'ms -', ' ', num2str(m*48-48+80), 'ms');
            else
                plotname = strcat(num2str(m*16-16),'ms');
            end
            title(plotname)
        end
    else % if whichlabels == 2, just calculate RDMs, do not plot
        RDM = computeRDM(squeeze(grandCM(m,:,:)));
        grandRDM(m,:,:) = RDM;
    end
    
    % save like this (with the RDMs) if multiple time windows:
    save(strcat(datapath, outputFile),'CM','accuracy','predY','pVal','classifierInfo','RSAinfo', 'grandCM', 'grandRDM');

end



