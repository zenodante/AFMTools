function sParameter = NSVarProcess(vars_input, vars_list)
%vars_input : the input from a function var
%vars_list : the vars names 
    for i = 1:length(vars_list) %check each vars in the list
        %if there is a match in the vars_input from a function
        var_matchs = strncmp(vars_input,vars_list(i),length(vars_list(i)));
        index = find(var_matchs,1);%find first match
        if ~isempty(index)%matched
            if(index(1) + 1)<=length(vars_input) %check the mistakes
                sParameter.(vars_list{i})= vars_input{index(1)+1};
            else
                warning('Function input parameter pairs outof index error.');
                sParameter.(vars_list{i})= NaN;
            end
        else %nothing matched
            sParameter.(vars_list{i})= NaN;
        end
    end
end