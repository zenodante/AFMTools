%% Bruker force curve filter script v0.1
% Don't use it for Resolve force curve file by the dll in this folder. 
% You need the dll in the v1.80 offline software for Resolve.

%%
%config area
file_folder = 'c:\GUI\test';
%the minimal boundary (nm)
seperation_minimal_boundary = 0;
%the maximal boundary (nm)
seperation_maximal_boundary = 400;
%'smaller_than','single_peak','not_smaller_than'
%single peak haven't been done yet...
filter_mode = 'smaller_than';
% nN
filter_force = -0.2;
%using new sensitivity and spring constant function havn't finished yet
using_new_sensitivity = false;
new_sensitivity = 0;
using_new_spring_constant = false;
new_spring_constant = 0;

baseline_correction = true;
% 0~1 range 0 is most far position from surface 1 is the trigger point
baselineFitRange = 0.5;
%base line correction methods 'shift_and_tilt' 'shift'
baseline_correction_mode = 'shift_and_tilt';

%end of config
%%
%Check folder statement
if (~isdir(file_folder))
    warning('Wrong file folder! please check');
    return;
end

folder_true = strcat(file_folder,'\true');
folder_false = strcat(file_folder,'\false');
if (exist(folder_true)||exist(folder_false))
    warning('There are already results folders existing.');
    return;
end

%%
%open files in the folder
acception = false;
file_list = dir(file_folder);

mkdir(file_folder,'true');
mkdir(file_folder,'false');
NSMU = NSMatlabUtilities();
%open a Bruker file
[file_num,file_num2] = size(file_list);

for i = 1:file_num
    i%show the number
    %go through all the file in the folder
    %if it it a sub folder, skip it
    if (file_list(i).isdir == true)
        continue;
    end
    
    filename = strcat(file_folder,'\',file_list(i).name);
    try
        NSMU.Open(filename);
    catch
        continue;
    end
    %check if want to use a new sensitivity value or spring constant vaule
    %then read curve in volt, otherwise read curve in newton
    if((using_new_sensitivity == true)||(using_new_spring_constant == true))
        [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel]  = NSMU.CreateForceZPlot(1 ,NSMU.VOLTS,0);
        % use sensitivity and spring constant to modified curve
        %todo
        
    else
        [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel]  = NSMU.CreateForceZPlot(1,NSMU.FORCE,1);
    end
    %%
    % shift the baseline of the curve
    CurveLength = length(xRetrace);
    
    if strcmp(baseline_correction_mode,'shift_and_tilt') 
        %the start index
        CurveFitStIndx = int32((1-baselineFitRange) * CurveLength);
        %find the baseline position value, correct the baseline
        baselineFit = fit(xRetrace(CurveFitStIndx:end),yRetrace(CurveFitStIndx:end),'poly1','normalize','on');
        yRetraceNew = yRetrace - baselineFit(xRetrace);
    end
    if strcmp(baseline_correction_mode,'shift')
        baselineFit = mean(yRetrace(CurveFitStIndx:end));
        yRetraceNew = yRetrace - baselineFit;
    end
    
    %find the min force in the curve(largest adhesion force point)
    [minForce,minForceIdx]=min(yRetraceNew);
 
    
    
    %%
    %Check the filter condition
    x_left = find(xRetrace>seperation_minimal_boundary,1);
    x_right = find(xRetrace>seperation_maximal_boundary,1);
    if strcmp(filter_mode ,'not_smaller_than')
        result = yRetraceNew(x_left:x_right)<filter_force ;
        if nnz(result) == 0 %none of the yRetrace vaule in the range smaller than the filter force
            acception = true;
        else
            acception = false;
        end
    end
    if strcmp(filter_mode ,'smaller_than')
        result = yRetraceNew(x_left:x_right)<filter_force ;
        if nnz(result) == 0 %none of the yRetrace vaule in the range smaller than the filter force
            acception = false;
        else
            acception = true;
        end
    end
    if strcmp(filter_mode,'single_peak')
       %todo 
    end
    %%
    % copy the file into ture or false folder
    if (acception == false )
        copyfile(filename,folder_false);
    else
        copyfile(filename,folder_true);
    end
end
