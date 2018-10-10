% Makes the image into a cirle and puts mid-grey around. Also adds a
% fixation cross. This is for a greyscale, normalized ensemble experiment

% G Vilidaite 18th July 2018

function makeNormalizedEnsembleStim

clear all
close all

% settings:
how_soft = 0.99; % third parameter determines how soft the window is
output_mode = 2; % 1 = .jpg; 2 = .mat

inputdir = uigetdir('~/Users/','Select directory containing the images');
savedir = uigetdir('~/Users/','Select directory to save output images');

inputimages = dir(strcat(inputdir,'/*.jpg'));

no_images = length(inputimages);

for im = 1:no_images
    currimage = imread(strcat(inputdir,'/',inputimages(im).name));
    
    imsize = size(currimage);
    
    % increasing contrast:
    currimage = imadjust(currimage);
    imagecell{im} = double(currimage);
end

% adding two blank fixation cross images
blankimage(1:850,1:850) = round(255/2);
imagecell{no_images+1} = uint8(blankimage); % twice
imagecell{no_images+2} = uint8(blankimage);

middle = round(imsize./2);
    
    
for im = 1:(no_images + 2) % plus two because of fixation cross screens
    % putting in a central fixation cross:

    
    currimage = imagecell{im};
    
    currimage((middle-3):(middle+3),(middle-30):(middle+30)) = round(255/2);  % horizontal grey stripe
    currimage((middle-30):(middle+30),(middle-3):(middle+3)) = round(255/2);  % vertical grey stripe
    currimage((middle-1):(middle+1),(middle-28):(middle+28)) = 255;  % horizontal white stripe
    currimage((middle-28):(middle+28),(middle-1):(middle+1)) = 255;  % vertical white stripe
    
    
    % if last image, replace white/grey fixation cross with black
    if im == (no_images + 2)
        currimage((middle-3):(middle+3),(middle-30):(middle+30)) = 0;  % horizontal grey stripe
        currimage((middle-30):(middle+30),(middle-3):(middle+3)) = 0;  % vertical grey stripe
    end
    
    imagecell{im} = currimage(2:849,2:849);
end



softwin = make_soft_window((imsize(1)-2),(imsize(2)-2), how_soft);

for im = 1:no_images % only the actual images
    imagecell{im} = uint8(((imagecell{im}-round(255/2)) .* softwin)+round(255/2));
    % multiplying the image contrast before adding softwin so that later
    % can be divided in order to make midgrey in the background
end

if output_mode == 1 % if we want .jpg's
    for im = 1:(no_images + 2) % plus two because of fixation cross screens

        if im > no_images
            imwrite(imagecell{im}, strcat(savedir,'/blank',num2str(im-no_images),'.jpg'))
          %  imshow(imagecell{im})
        else
            imwrite(imagecell{im}, strcat(savedir,'/',inputimages(im).name))
        end
    end

else % if we want .mat files that are ready for xDiva
    w_cross_im = imagecell{(no_images + 1)};
    k_cross_im = imagecell{(no_images + 2)};
    
    imageSequence = uint32(zeros(60,1));
    imageSequence(1) = 1;
    imageSequence(16) = 2;
    imageSequence(31) = 3;
    imageSequence(46) = 4;
    imageSequence(60) = 3;
    
    count = 1;
    for im = 1:no_images
        images(:,:,1,1) = w_cross_im;
        images(:,:,1,2) = imagecell{im};
        images(:,:,1,3) = k_cross_im;
        images(:,:,1,4) = k_cross_im;
        
        switch im
            case num2cell(1:6)
                im_name = 'HumanBodies';
                cond_no = 1;
            case num2cell(7:12)
                im_name = 'HumanFaces';
                cond_no = 2;
            case num2cell(13:18)
                im_name = 'AnimalBodies';
                cond_no = 3;
            case num2cell(19:24)
                im_name = 'AnimalFaces';
                cond_no = 4;
            case num2cell(25:30)
                im_name = 'InanimateNatural';
                cond_no = 5;
            case num2cell(31:36)
                im_name = 'InanimateArtificial';
                cond_no = 6;
        end
        
        
        im_file_name = sprintf('%d_%s_%02d.mat',cond_no,im_name,count);
        save(strcat(savedir,'/',im_file_name), 'images', 'imageSequence')
        
        count = count + 1;
        if count > 6
            count = 1;
        end
        
    end
end
end
%--------------------------------------------------------------------------
