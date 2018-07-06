function [output indexes] = gv_make_sliding_windows(input, Nwindows, dim)

% This function slices the input matrix into the number of windows
% specified by Nwindows along the dimension dim.

% Output:
% indexes - 2D matrix of indexes indicating the start and end of each
%           window. Rows are windows, column 1 is the start and column
%           2 is the end
% output - cell array with windows of data contained in separate cells

% Input:
% input - 1D, 2D or 3D matrix which needs segmenting
% Nwindows - how many windows to segment input into (minimum is 3)
% dim - which dimension to perform the window segmentation on

% NOTE: if the windows do not neatly fit into the matrix, there might be
% datapoints at the end that are not used.

% GV June 5th 2018

% TODO: make it so that you can specify window length instead of number of
% windows


inputsize = size(input);

targetdimlength = inputsize(dim);

windowdenom = Nwindows./2+0.5; % to divide up the input into X number of
% sliding windows (which each start halfway through the previous window),
% need to divide the input but half of the Nwindows plus half a window.
% This gives the correct denominator:

% E.g.
% |_____________input______________|
% |__1__|__3__|__5__|__7__|__9__|
%    |__2__|__4__|__6__|__8__|_10__|
%    ^     ^     ^     ^     ^    ^
%    1  +  1  +  1  +  1  +  1  + 0.5 = 5.5 = Nwindows./2+0.5 - this is the correct
%    denominator for the division.

windowsize = floor(targetdimlength ./ windowdenom);

count = 1;

for n = 1:Nwindows
    index1 = count;
    index2 = count + windowsize;
    
    indexes(n,1) = index1;
    indexes(n,2) = index2;
    
    if length(inputsize) == 1 % if input is 1D vector
        output{n} = input(index1:index2);
    elseif (length(inputsize) == 2)&&(dim==1) % if input is 2D matrix and dim is 1
        output{n} = input(index1:index2,:);
    elseif (length(inputsize) == 2)&&(dim==2) % if input is 2D matrix and dim is 2
        output{n} = input(:,index1:index2);
    elseif (length(inputsize) == 3)&&(dim==1) % if input is 3D matrix and dim is 1
        output{n} = input(index1:index2,:,:);
    elseif (length(inputsize) == 3)&&(dim==1) % if input is 3D matrix and dim is 2
        output{n} = input(:,index1:index2,:);
    elseif (length(inputsize) == 3)&&(dim==1) % if input is 3D matrix and dim is 3
        output{n} = input(:,:,index1:index2);
    else
        error('Invalid dim or size of input matrix');
    end
    
    count = count + floor(windowsize./2);

end

end