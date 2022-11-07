% animated image demonstrating the inversion of action of hip muscles
% muscle origin & insertion data:
% Horsman, K, Koopman HFJM, et al. (2007). Morphological muscle and joint
% parameters for musculoskeletal modelling of the lower extremity. Clinical
% Biomechanics, 22: 239-247.

% NOTE: I started out just using cell arrays to easily track variables -
% this has turned out to require lots of additional considerations, but I
% am so far into at this point I am going to follow it through - I will
% likely refactor this later OR if I hit a big enough wall - just note I
% realize using cell arrays is less than ideal but is OK performance wise
% with the small data set used here

%% load data from .txt
    % keep the data as cell arrays - allows string finding and numberical
    % iteration for looping for computations
muscle_c = table2cell(readtable("muscle_OI.txt")); % muscle IO
bone_c = table2cell(readtable("bony_landmark.txt")); % landmarks

% generate muscle origin reference cell array for later
for r = 1:1:size(muscle_c,1)
    for s = 1:1:4
        origin_ref{r,s} = muscle_c{r,s};
    end
end

 % fill bone_c with empty cells to allow cell array concatenation
for i = 5:1:7
    for j = 1:1:size(bone_c,1)
        bone_c{j,i} = [];
    end
end

mb_c = [muscle_c ; bone_c]; % concatenating cell arrays
muscle_count = size(muscle_c,1); % get muscle count for future automation

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

% rotate femur into flexion by n-degrees until X degrees

 % create struct to hold all new muscle insertio data
 % index neutral coordinates
for r = 1:1:muscle_count
    insertion_s(1).in{r,1} = muscle_c{r,1};
    for l = 5:1:7
        insertion_s(1).in{r,l-3} = muscle_c{r,l};
    end
end

 % get neutral FME vector as regular array
c_pos = size(mb_c,1);
neutral_FME = [mb_c{c_pos, 2}; mb_c{c_pos, 3}; mb_c{c_pos, 4}];
clearvars c_pos % only used for prior calculation
mb_ind = size(mb_c,1) + 1; % used for indexing into mb_c
sf_count = 2; % keep track of current struct field number
 % set peak flexion angle & flexion steps
max_flexion_angle = 90;
flexion_steps = 5;

for angle = 0:flexion_steps:max_flexion_angle
      % automated row name generator for mb_c
    row_str = append("FE_Mechanical_axis_", int2str(angle), "_deg");
    mb_c{mb_ind,1} = row_str;
      % rotate mechanical axis -> returns 1x3 and x3 1x1 arrays
    [FME_xyz, mb_c{mb_ind, 2}, mb_c{mb_ind, 3}, mb_c{mb_ind, 4}] = ...
        rotateFME(angle, neutral_FME);
    mb_ind = mb_ind + 1; % ++cell arrray index
      
      % compute new muscle insertion site relative to HJC [0,0,0]
      % index into insertion struct
    for adj_i = 1:1:muscle_count
         % insert row string
        insertion_s(sf_count).in{adj_i,1} = mb_c{adj_i, 1};
         % create reg array of insertion data
        n_insertion = [mb_c{adj_i,5}, mb_c{adj_i,6}, mb_c{adj_i,7}];
         % find insertion in global coorinate system
        rot_insertion = FME_xyz + n_insertion;
         % index rotated insertion into struct cell array
        for ind = 1:1:3
            insertion_s(sf_count).in{adj_i, ind+1} = rot_insertion(1,ind);
        end
    end
    sf_count = sf_count + 1; % ++struct field counter
end

%% test plot3
% keep building this out - not complete
fig1 = figure;
view(168,2);
for s = 1:1:step_number
    hold on
    for plt = 1:1:muscle_count
        trend_style = getTrendStyle(plt, origin_ref);
        % z,x,y
        plot3([origin_ref{plt,4}; insertion_s(1).in{plt,4}],...
            [origin_ref{plt,2}; insertion_s(1).in{plt,2}],...
            [origin_ref{plt,3}; insertion_s(1).in{plt,3}],...
            trend_style);
    end
    plot3(0,0,0, 'ko'); % HJC
    plot3([0; mb_c{61,4}], [0; mb_c{61,2}], [0; mb_c{61,3}], 'k-'); % fem mech axis
    plot3(0,0,0, 'ko'); % Epicondyle centre
    hold off
    cf = getframe(fig1); % capture current plot as movie
    hold_frames{?} = frame2im(cf); %convert frame to RGB image
end


%% example of working to-be-gif code
fig_o = figre; %figure obj
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
