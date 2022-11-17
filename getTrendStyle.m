function [cs] = getTrendStyle(cell_val)
    if contains(cell_val, "Adductor");
        cs = 'r--';
    elseif contains(cell_val, "GluteusMax");
        cs = 'b--';
    elseif contains(cell_val, "GluteusMed");
        cs = 'g--';
    elseif contains(cell_val, "GluteusMin");
        cs = 'm--';
    else
        disp("No trend style found - default used.");
    end
end