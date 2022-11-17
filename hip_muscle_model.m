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
clear
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
    bone_str{ib,1} = bone_c{ib,1}; % used figure labeling
end

 % allocate muscle origin data to separate array to increase loop interp
muscle_origins = NaN(ROW_COLUMN.muscle(1,1), 3);
for i = 1:1:ROW_COLUMN.muscle(1,1)
    for j = 2:1:4
        muscle_origins(i,j-1) = muscle_c{i,j};
    end
end

clearvars ib im % clear loop vars
% convert cell arrays -> normal arrays
for i = [1 2]
     % allocate string to improve readability in block
    cSTR = mb_str{i,1}; % 'muscle' or 'bone'
     % allocate NaNs to improve array alloc performance
    IO_STRUCT(1).(cSTR) = NaN(ROW_COLUMN.(cSTR)(1,1), 3);
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
        % if muscle -> 5:1:7 into 1:1:3 (no origin - need correction factor
        if i == 1
            af = 3;
        else
            af = 0;
        end
        for col = af+2:1:ROW_COLUMN.(cSTR)(1,2)
            IO_STRUCT.(cSTR)(row,col-af-1) = temp_c{row,col}; % note col-1 for IO_s
        end
    end
    clearvars temp_c cSTR col i muscle_c row
end

 % clean up workspace
clearvars af bone_c j 

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
    cSTR = mb_str{i,1};
    for j = 1:1:ROW_COLUMN.(cSTR)(1,1) % need to correct for bone+2
        n_EPI_MID_ins.(cSTR)(j, 1:3) = IO_STRUCT(1).(cSTR)(j,:) - ...
            temp_FMA;
    end
end
clearvars cSTR i j temp_FMA

% rotate FMA for each desired hip flexion angle

 % rotate unit vectors of embedded thigh LCS
thigh_LCS.X(1,:) = [5 0 0];
thigh_LCS.Y(1,:) = [0 5 0];
thigh_LCS.Z(1,:) = [0 0 5];
XYZ_str{1,1} = 'X'; XYZ_str{2,1} = 'Y'; XYZ_str{3,1} = 'Z';
XYZ_str{1,2} = 'r'; XYZ_str{2,2} = 'g'; XYZ_str{3,2} = 'b';

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
    rang = deg2rad(ang);
    rot_z = rotateVecAboutZAxis(rang, n_FMA);
    IO_STRUCT(sc).bone(FMA_ridx,:) = rot_z;
     
     % roate embedded thigh LCS (x3 unit vectors)
    for u = 1:1:3
        thigh_LCS.(XYZ_str{u,1})(sc,:) = ...
            rotateVecAboutZAxis(rang, thigh_LCS.(XYZ_str{u,1})(1,:).');
    end

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
clearvars n_FMA ang rot_z sc

% test plot3
 % femoral landmark labels
Z = 3; X = 1; Y = 2; % for readability
label_offset = 0.5; % offsets landmark labels to prevent overlap
fig1 = figure("WindowState", "maximized");
pause(1); % give time to resize figure if auto saving images
view(168,2);
for psc = 1:1:1 % sc from previous block (field size of IO_STRUCT)
    hold on
    for plt = 26:1:ROW_COLUMN.muscle(1,1)
        % z,x,y
        plot3([muscle_origins(plt, Z) ; IO_STRUCT(psc).muscle(plt, Z)],...
              [muscle_origins(plt, X) ; IO_STRUCT(psc).muscle(plt, X)],...
              [muscle_origins(plt, Y) ; IO_STRUCT(psc).muscle(plt, Y)],...
              trend_styles{plt,1},...
              'LineWidth', 1.5);
    end

     % plot embedded rotating thigh LCS...
     % quiver3(0,0,0, +lateral (Z), +anterior (X),+superior (Y))
    for q = 1:1:3
        plt_uv(q) = quiver3(0,0,0,...
            thigh_LCS.(XYZ_str{q,1})(psc,3),...
            thigh_LCS.(XYZ_str{q,1})(psc,1),...
            thigh_LCS.(XYZ_str{q,1})(psc,2));
        plt_uv(q).LineWidth = 2;
        plt_uv(q).Color = XYZ_str{q,2};
    end

     % rotated FMA vector
    plot3([0; IO_STRUCT(psc).bone(FMA_ridx, Z)],...
          [0; IO_STRUCT(psc).bone(FMA_ridx, X)],...
          [0; IO_STRUCT(psc).bone(FMA_ridx, Y)],...
          'k-', 'LineWidth', 4);

     % plot pelvis boney landmarks -> these DO NOT change with FME rotation
    for plm = 1:1:4
        XYZ(1,:) = [IO_STRUCT(1).bone(plm, Z),...
                    IO_STRUCT(1).bone(plm, X),...
                    IO_STRUCT(1).bone(plm, Y)];
        pbplot = plot3(XYZ(1,1), XYZ(1,2), XYZ(1,3), '.', 'MarkerSize', 30);
        pbplot.Color = '#A2142F';
        text(XYZ(1,1)+label_offset, XYZ(1,2)+label_offset, XYZ(1,3)+label_offset,...
            bone_str{plm,1},... % string
            'HorizontalAlignment', 'right',...
            'FontWeight', 'bold', 'FontSize', 14);
    end

     % plot rotated femoral landmarks -> FGT, MFE, LFE
    for flm = plm+1:1:7
         % allocate since both plot3 & text() will use coord
        XYZ(1,:) = [IO_STRUCT(psc).bone(flm, Z),...
                    IO_STRUCT(psc).bone(flm, X),...
                    IO_STRUCT(psc).bone(flm, Y)];
         % plot points
        plot3(XYZ(1,1), XYZ(1,2), XYZ(1,3), 'k.', 'MarkerSize', 30);
         % add marker label
        text(XYZ(1,1)+label_offset, XYZ(1,2)+label_offset, XYZ(1,3)+label_offset,...
            bone_str{flm,1},... % string
            'HorizontalAlignment', 'right',...
            'FontWeight', 'bold', 'FontSize', 14);
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
