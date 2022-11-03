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

 % fill bone_c with empty cells to allow cell array concatenation
for i = 5:1:7
    for j = 1:1:size(bone_c,1)
        bone_c{j,i} = [];
    end
end

mb_c = [muscle_c ; bone_c]; % concatenating cell arrays
muscle_count = size(muscle_c,1); % get muscle count for future automation
clearvars muscle_c bone_c % clear original cell arrays

% determine femoral mechanical axis
 % assign cell array length for automated appending
ind = size(mb_c,1)+1; % track new additions to bone_c cell array

 % 1/2 vec between femoral epicondyles
mb_c{ind,1} = "Epi_Midpoint";
[mb_c{ind, 2}, mb_c{ind, 3}, mb_c{ind, 4}] = ...
    findVector(mb_c, "LFE", "MFE", 0.5, "b2p");

 % vector from HJC to 1/2 epi vec
ind = ind +1;
mb_c{ind,1} = "FE_Mechanical_axis";
[mb_c{ind, 2}, mb_c{ind, 3}, mb_c{ind, 4}] = ...
    findVector(mb_c, "MFE", "Epi_Midpoint", 1, "resultant");

% find vector between mEd & muscle insertions in neutral
for i = 1:1:muscle_count
    % n_mEd = neutral hip postur_vector from middle Epicondyle distance
    n_mEd_insertion{i,1} = mb_c{i,1}; % assign same row name
    [n_mEd_insertion{i,2}, n_mEd_insertion{i,3}, n_mEd_insertion{i,4}] = ...
        findVector(mb_c, mb_c{i,1}, "FE_Mechanical_axis", 1, "b2p");
end

%% rotate femur into flexion by n-degrees until 90 degrees
    % rotate femoral mechanical axis vector
    % find new vector from middle epicondyle distance for ea muscle
    % insertion

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
