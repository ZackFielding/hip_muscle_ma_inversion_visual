function [struct_s] = getRotatedCoord(struct_s, ss_count, FME_xyz)
    % get struct row # for looping
    row_count = size(struct_s(1).in, 1);
    for i = 1:1:row_count
         % insert row string
        struct_s(ss_count).in{i,1} = struct_s(1).in{i, 1};
         % create reg array of insertion data
        neutral_xyz = [struct_s(1).in{i,2},...
                        struct_s(1).in{i,3},...
                        struct_s(1).in{i,4}];
         % find insertion in global coorinate system
        rotated_xyz= FME_xyz + neutral_xyz;
         % index rotated insertion into struct cell array
        for ind = 1:1:3
            struct_s(ss_count).in{i, ind+1} = rotated_xyz(1,ind);
        end
    end
end