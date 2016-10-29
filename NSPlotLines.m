%Plot lines in one 2d array

function NSPlotLines(array_source,line_index,varargin)
    %array_source is the AFM image 2d array set
    %
    option_var = {'scan_size_x' 'scan_size_y' 'x_title' 'y_title' 'lines_thickness' 'color'};
    sOption_pars = NSVarProcess(varargin, option_var);
    
    
end

