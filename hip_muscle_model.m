% animated image demonstrating the inversion of action of hip muscles
% muscle origin & insertion data:
% Horsman, K, Koopman HFJM, et al. (2007). Morphological muscle and joint
% parameters for musculoskeletal modelling of the lower extremity. Clinical
% Biomechanics, 22: 239-247.

%% load data from .txt
    % keep the data as cell arrays - allows string finding and numberical
    % iteration for looping for computations
muscle_c = table2cell(readtable("muscle_OI.txt")); % muscle IO
bone_c = table2cell(readtable("bony_landmark.txt")); % landmarks

    % determine femoral mechanical axis
 % assign cell array length for automated appending
bcs = size(bone_c,1); % track new additions to bone_c cell array
for i = 1:1:2
     % determine row name, vector distance, and lateral & medial landmarks
    switch i
        case 1
            row_string = "LFE_MFE";
            adj_factor = 0.5;
            lateral_lm = "LFE"; medial_lm = "MFE";
        case 2
            row_string = "FE_Mechanical_axis";
            adj_factor = 1;
            lateral_lm = "LFE_MFE"; medial_lm = "HJC";
    end
     % adjust index to append to current cell array
    ind = bcs + i;
     % assign row name
    bone_c{ind,1} = row_string;
     % output vector length with given landmark strings & adjustment factor
    [bone_c{ind, 2}, bone_c{ind, 3}, bone_c{ind, 4}] = ...
    findVector(bone_c, lateral_lm, medial_lm, adj_factor); % find 1/2 point between MFE & LFE
end
%% example of working to-be-gif code
fig_o = figure; %figure obj
for i = 1:1:5
    plot3(x:x+i, y:y+i, z:z+i);
    drawnow
    campos([0, +20, -20]);
    cf = getframe(fig_o); % capture current plot as movie
    hold_frames{i} = frame2im(cf); %convert frame to RGB image
    pause(0.5);
end

% export figure as gif
close(fig_o); % close figre
file = "test_animation.gif"; % file name
for j = 1:1:5
    [ind_im, c_map] = rgb2ind(hold_frames{j}, 256);
    if j == 1
        imwrite(ind_im, c_map, file, "gif", "LoopCount", Inf, "DelayTime", 1);
    else
        imwrite(ind_im, c_map, file, "gif", "WriteMode", "append", "DelayTime", 1);
    end
end
