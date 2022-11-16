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

 % strings for struct automation
mb_str{1,1} = "muscle";
mb_str{2,1} = "bone";

 % row and column lengths: row (1,1), col (1,2)
ROW_COLUMN.muscle = size(muscle_c);
ROW_COLUMN.bone = size(bone_c);

% create hash map of muscle names & array row positions
 % create empty hash first (cell arrays do not allow vector indexing)
IO_MAP.muscle = containers.Map('KeyType', 'char', 'ValueType', 'int32');
for im = 1:1:ROW_COLUMN.muscle(1,1)
    IO_MAP.muscle(muscle_c{im,1}) = im;
    trend_styles{im,1} = getTrendStyle(muscle_c{im,1});
end

% create hash map of landmark names & array row positions
IO_MAP.bone = containers.Map('KeyType', 'char', 'ValueType', 'int32');
for ib = 1:1:ROW_COLUMN.bone(1,1)
    IO_MAP.bone(bone_c{ib,1}) = ib;
end
%%
clearvars ib im % clear loop vars
% convert cell arrays -> normal arrays
for i = [1 2]
     % allocate string to improve readability in block
    cSTR = mb_str{i,1}; % 'muscle' or 'bone'
     % allocate NaNs to improve array alloc performance
    IO_STRUCT(1).(cSTR) = NaN(ROW_COLUMN.(cSTR)(1,1),... % row count
                        ROW_COLUMN.(cSTR)(1,2)-1); % col count -1
     % temp cell array to remove need for repetitive if-else run
    switch i
        case 1 
            temp_c = muscle_c;
        case 2
            temp_c = bone_c;
        otherwise
            disp("muscle and/or bone cell array not found prior to struct indexing.");
    end

    for row = 1:1:ROW_COLUMN.(cSTR)(1,1)
        for col = 2:1:ROW_COLUMN.(cSTR)(1,2)
            IO_STRUCT.(cSTR)(row,col-1) = temp_c{row,col}; % note col-1 for IO_s
        end
    end
    clearvars temp_c
end

 % clean up workspace
clearvars -except IO_STRUCT IO_MAP mb_str ROW_COLUMN
% determine femoral mechanical axis (FMA) vector

% Epicondyle mid point (EPI_MID)
 % increment bone array row count -> factor for new index
ROW_COLUMN.bone(1,1) = ROW_COLUMN.bone(1,1) + 1;
 % index new string identifier into map
IO_MAP.bone("EPI_MID") = ROW_COLUMN.bone(1,1);
 % find mid way point
IO_STRUCT(1).bone(ROW_COLUMN.bone(1,1), 1:3) = ...
  ( (IO_STRUCT(1).bone(cell2mat(values(IO_MAP.bone, {'LFE'})), 1:3) - ...
    IO_STRUCT(1).bone(cell2mat(values(IO_MAP.bone, {'MFE'})), 1:3)) ...
    .* 0.5...
   ); % = (LFE - MFE) * 0.5

% Femoral mechanical axis (FMA)
 % increment bone array row count -> factor for new index
ROW_COLUMN.bone(1,1) = ROW_COLUMN.bone(1,1) + 1;
 % index new string identifier into map
IO_MAP.bone("FMA") = ROW_COLUMN.bone(1,1);
 % find mid way point
IO_STRUCT(1).bone(ROW_COLUMN.bone(1,1), 1:3) = ...
  ( IO_STRUCT(1).bone(cell2mat(values(IO_MAP.bone, {'MFE'})), 1:3) + ...
    IO_STRUCT(1).bone(cell2mat(values(IO_MAP.bone, {'EPI_MID'})), 1:3) ...
   ); % = MFE + EPI_MID

 % allocate arrays
n_EPI_MID_ins.muscle = NaN(ROW_COLUMN.muscle(1,1), 3); % only need insertion
n_EPI_MID_ins.bone = NaN(ROW_COLUMN.bone(1,1), 3); % original == x3 col.

 % temp FMA to improve computation readability & performance
 % most of bone result -> not used -> stays consistent with Map
temp_FMA = IO_STRUCT(1).bone(cell2mat(values(IO_MAP.bone, {'FMA'})), 1:3);
for i = [1 2]
    switch i % insertion vec for for muscle - all col for bone
        case 1
            row_vec = 4:1:6;
        case 2
            row_vec = 1:1:3;
    end

    cSTR = mb_str{i,1};
    for j = 1:1:ROW_COLUMN.(cSTR)(1,1) % need to correct for bone+2
        n_EPI_MID_ins.(cSTR)(j, 1:3) = IO_STRUCT(1).(cSTR)(j, row_vec) - ...
            temp_FMA;
    end
end
clearvars cSTR i j temp_FMA

% rotate FMA for each desired hip flexion angle

FMA_ridx = cell2mat(values(IO_MAP.bone, {"FMA"}));
n_FMA = [IO_STRUCT(1).bone(FMA_ridx,1); 
        IO_STRUCT(1).bone(FMA_ridx,2); 
        IO_STRUCT(1).bone(FMA_ridx,3)]; % store neutral FMA vec to reduce func calls
 % compute struct sizes to reduce func calls
LENGTH_STRUCT(1,1) = size(IO_STRUCT(1).muscle, 1);
LENGTH_STRUCT(2,1) = size(IO_STRUCT(1).bone, 1);

fstep = 5; % angle steps
fstep_stop = 90; % max angle
sc = 2; % for indexing into muscle & bone struct

for ang = fstep:fstep:fstep_stop
     % z-axis rotation matrix * neutral FMA vector
    rot_z = [cos(ang), -sin(ang), 0;
          sin(ang), cos(ang), 0;
          0, 0, 1] * n_FMA;
    IO_STRUCT(sc).bone(FMA_ridx,:) = rot_z;
     % rotated FMA + neutral muscle insertions & femoral landmarks
    for mb = [1 2]
        cSTR = mb_str{mb,1}; % store current outcome string
         % neutral FMA + vector from mid epi for all muscle insertions &
         % femoal boney landmarks
        for idx = 1:1:LENGTH_STRUCT(mb,1)
            IO_STRUCT(sc).(cSTR)(idx, :) ...
                = rot_z.' + n_EPI_MID_ins.(cSTR)(idx, :);
        end
    end
    sc = sc + 1; % ++struct field tracker
end
clearvars n_FMA FMA_r_idx ang rot_z sc
%% test plot3

fig1 = figure;
view(168,2);
for s = 1:1:sc % sc from previous block (field size of IO_STRUCT)
    hold on
    for plt = 1:1:muscle_count
        % z,x,y
        plot3([ ; ],...
            [ ; ],...
            [ ; ],...
            trend_style(plt,1);
    end
     % FME
    FME_row_ind = FME_row_ind + s;
    plot3([0; mb_c{FME_row_ind,4}],...
            [0; mb_c{FME_row_ind,2}],...
            [0; mb_c{FME_row_ind,3}], 'k-');
     % plot femoral boney landmarks -> these change with FME rotation
    for b = 1:1:femoral_lm_count
        plot3([landmark_s(s).in{b,4}],...
                [landmark_s(s).in{b,2}],...
                    [landmark_s(s).in{b,3}], 'k*');
    end

     % plot pelvis boney landmarks -> these DO NOT change with FME rotation
    for pb = 1:1:4
        pbplot = plot3(bone_c{pb,4},...
            bone_c{pb,2},...
            bone_c{pb,3}, '*');
        pbplot.Color = '#A2142F';
    end

    hold off
    %pause(3);
    %close;
    %cf = getframe(fig1); % capture current plot as movie
    %hold_frames{?} = frame2im(cf); %convert frame to RGB image
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
