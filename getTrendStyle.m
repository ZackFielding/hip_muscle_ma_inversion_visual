function [cs] = getTrendStyle(c_row, array_c)
    if contains(array_c{c_row,1}, "Adductor");
        cs = 'r-';
    elseif contains(array_c{c_row,1}, "GluteusMax");
        cs = 'b-';
    elseif contains(array_c{c_row,1}, "GluteusMed");
        cs = 'g-';
    elseif contains(array_c{c_row,1}, "GluteusMin");
        cs = 'm-';
    else
        disp("No trend style found - default used.");
    end
end