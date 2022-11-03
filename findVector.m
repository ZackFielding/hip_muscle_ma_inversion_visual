function [x_cor, y_cor, z_cor] = findVector...
    (c_array, llm, mlm, adj_factor, method_str)

% set both to 0 for error handling
llm_row = 0;
mlm_row = 0;

for ind = 1:1:size(c_array,1)
    if matches(c_array{ind,1}, llm) == 1 % found right side match
        llm_row = ind;
    elseif matches(c_array{ind,1}, mlm) == 1 % found left side match
        mlm_row = ind;
    end
end

 % throw errros if right and left indexes could not be found and/or
 % computation method string is incorrectly entered
assert(llm_row ~=0, "Could not find lateral land mark string in provided cell array");
assert(mlm_row ~=0, "Could not find medial land mark string in provided cell array");
assert(strcmp("b2p", method_str) || strcmp("resultant", method_str),...
    "Vector computation method incorrectly entered");

for col = 2:1:4
     % determine computation method
    if strcmp("b2p", method_str);
        t_val = adj_factor * (c_array{llm_row,col} - c_array{mlm_row,col});
    else strcmp("resultant", method_str);
        t_val = adj_factor * (c_array{llm_row,col} + c_array{mlm_row,col});
    end
    switch col
        case 2
            x_cor = t_val;
        case 3
            y_cor = t_val;
        case 4
            z_cor = t_val;
    end
end

end % function end