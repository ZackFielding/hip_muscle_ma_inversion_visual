function [xyz, x_cor, y_cor, z_cor] = rotateFME(angle, n_FME)
    % custom function allows easier indexing into cell array
        % rotation matrix for angle about z-axis (flexion-extension)
    angle = deg2rad(angle);
    rotation_m_z = [cos(angle), -sin(angle), 0;
                  sin(angle), cos(angle), 0;
                  0, 0, 1];
    xyz = rotation_m_z * n_FME;
    x_cor = xyz(1,1);
    y_cor = xyz(2,1);
    z_cor = xyz(3,1);
end