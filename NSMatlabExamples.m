function NSMatlabExamples(ExampleIndex)

%-----------------------------------------------------------------------------------------
% NSMatLabExamples provides examples of how to use The Matlab Toolbox (NSMatlabUtilites)
% to retrieve, display and process data from NanoScope Data Files
%
%  Run: NSMatlabExamples(n)
%
%       n   Filetype                         Description
%       --  --------                         -----------
%       1   Force File                       Display force curves - time, z, and separation
%       2   Force Volume File                Display FV image and curves - time and separation
%       3   PeakForce Capture                Display PF image and curves - time and separation
%       4   PeakForce Capture                Compute Modulus from every 100th curve
%       5   HSDC (High Speed Data Capture)   Display HSDC Data vs. time - multiple channels
%       6   SPM Image                        Display SPM Image, multiple channels
%       7   Force Hold Data                  Display Force curve and Hold data
%       8   Force Volume Hold Data           Display FV Image, Hold, and FV curves - multiple channels
%       9   Script File Example              Display all segments, multiple channels
%       10  Script File Example              Display single segment, multiple channels
%       11  NanoDrive                        Display a NanoDrive image 
%-----------------------------------------------------------------------------------------


    delete(findall(0,'Type','figure'))
    switch ExampleIndex
        case 1
            NSMatlabForceFileExample();
        case 2
            NSMatlabForceVolumeExample();
        case 3
            NSMatlabPeakForceCaptureExample1();
        case 4
            NSMatlabPeakForceCaptureExample2();
        case 5
            NSMatlabHSDCExample();
        case 6
            NSMatlabImageExample();
        case 7
        	NSMatlabForceHoldExample();
        case 8
            NSMatlabForceVolumeHoldExample();
        case 9
            NSMatlabScriptExample(true);
        case 10
            NSMatlabScriptExample(false);
        case 11
            NSMatlabImageNanoDriveExample();
        otherwise
            error('No example for this index %d.', ExampleIndex);
    end
end

function NSMatlabForceFileExample()
    NSMU = NSMatlabUtilities();
    
    %open a force curve file   
    NSMU.Open(which('Force.spm'));
    
    %----------------------------
    %Force timed plot
    f = figure();
    movegui(f,'northwest');
    
    %get timed data (Volts) of channel 1
    [xData, yData, xLabel, yLabel] = NSMU.CreateForceTimePlot(1, NSMU.VOLTS);
    [chanDesc] = NSMU.GetDataTypeDesc(1);   
    plot(xData, yData);
    
    title (strcat(chanDesc, ' vs. Time'));
    xlabel(xLabel);
    ylabel(yLabel);
    
    %---------------------------
    % Force z plot   
    f = figure();
    movegui(f,'north');
    hold on;
    
    %Get F vs Z plot of channel 1
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceZPlot(1, NSMU.FORCE, 0);
    plot(xTrace, yTrace);
    plot(xRetrace, yRetrace);
    
    title ('Force vs. Z');
    xlabel(xLabel);
    ylabel(yLabel);
 
    %---------------------------
    % Force separation plot      
    f = figure();
    movegui(f,'northeast');
    hold on;
    
    %get F vs tip-sample separation plot of channel 1 - retrace 
    %Note: last argument = 1 in CreateForzeZPlot => separation data
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceZPlot(1, NSMU.FORCE, 1);
    %uncomment below lines if you want to plot the trace data
    %plot(xTrace, yTrace);
    plot(xRetrace, yRetrace);
      
    %plot the contact region
    contactPointIndex = FindContactPoint(xRetrace, yRetrace);
    [regionBottom, regionTop] = ComputeContactRegionBounds(xRetrace, yRetrace, contactPointIndex, 10, 90);
    v = zeros(size(xRetrace));
    v(:)= regionTop;
    plot(xRetrace,v,'m');
    v(:)= regionBottom;
    plot(xRetrace,v,'m');
   
    title ('Force vs. Separation');
    xlabel(xLabel);
    ylabel(yLabel);
    
    %---------------------------
    %calculate some values and display in command window
    [index1, index2] = ComputeMarkers(xRetrace, yRetrace,regionTop, regionBottom);
    K = ExponentialFit(xRetrace, yRetrace, index1, index2, contactPointIndex);
    PR = NSMU.GetPoissonRatio()
    TR = NSMU.GetTipRadius()
    E = GetYoungsModulus(K, PR, TR)
    NSMU.Close();
end

function NSMatlabForceHoldExample()
    NSMU = NSMatlabUtilities();
    
    %open a force curve file which contains a hold segment
    NSMU.Open(which('ForceHold.spm'));
   
    %----------------------------
    %Force timed plot
    f = figure();
    movegui(f,'northwest');
    
    %get timed data (Metric) of channel 1
    [xData, yData, xLabel, yLabel] = NSMU.CreateForceTimePlot(1, NSMU.METRIC);
    [chanDesc] = NSMU.GetDataTypeDesc(1);   
    plot(xData, yData);
    
    title (strcat(chanDesc, ' vs. Time'));
    xlabel(xLabel);
    ylabel(yLabel);

    %----------------------------
    %Force Hold data plot 
    f = figure();
    movegui(f,'north');  
    
    holdTimeSecs = NSMU.GetForceHoldTime(1);
  
    %get hold data (metric units) for channel
    xAxis = linspace(0, holdTimeSecs,  NSMU.GetNumberOfHoldPoints(1))';
   [rawData, scaleUnit, dataTypeDesc] = NSMU.GetForceHoldData(1, NSMU.METRIC);
    plot(xAxis, rawData);
    
    title (strcat('Force Hold Data:',{' '}, chanDesc, ' vs. Time'));    
    xlabel('Time (secs)');
    ylabel(strcat(dataTypeDesc, ' (', scaleUnit, ')'));
 
    NSMU.Close();
end


function NSMatlabForceVolumeExample()
    NSMU = NSMatlabUtilities();
    
    %open a force volume file
    NSMU.Open(which('FV.spm'));
    
    %get number of image pixels & number of force curves in each scan line
    [imagePixel, forVolPixel] = NSMU.GetForceVolumeScanLinePixels();     
    NumberOfCurves = NSMU.GetNumberOfForceCurves();
    
    %---------------------------------
    %Display image
    f = figure();
    movegui(f,'northwest');
    
   %Get FV Image Data
    [data, scaleUnit, dataTypeDesc] = NSMU.GetForceVolumeImageData(NSMU.METRIC);
    
    image(flipud(data),'CDataMapping','scaled');
    set(gca,'YDir','normal');
    axis('tight', 'square'); 
    colormap('Copper');
    hold on;
    plot(1, 1, 's', 'MarkerSize', 10,'MarkerEdgeColor','b', 'MarkerFaceColor', 'b')   
    plot(imagePixel, 1, 's', 'MarkerSize', 10,'MarkerEdgeColor','c', 'MarkerFaceColor','c')   
    plot(imagePixel, imagePixel, 's', 'MarkerSize', 10,'MarkerEdgeColor','g', 'MarkerFaceColor','g')   
    %colorbar();
    
    title(strcat('Force Volume',{' '}, dataTypeDesc, ' Image')); 
    xLabel = NSMU.GetScanSizeLabel();
    xlabel(xLabel);
    
    %---------------------------------
    %Force curves against time
    f = figure();
    movegui(f,'north');    
    hold on;
              
    %plot force curve (against time) for 3 corner pixels
    [chanDesc] = NSMU.GetDataTypeDesc(2); %Chan 1 is Image channel, so grab force curve data type from chan 2  
    
    [xData, yData, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveTimePlot(1, NSMU.METRIC); %bottom left curve
    plot(xData, yData,'b-');
    
    [xData, yData, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveTimePlot(forVolPixel, NSMU.METRIC); %bottom right curve
    plot(xData, yData,'c-');
    
    [xData, yData, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveTimePlot(NumberOfCurves, NSMU.METRIC); %top right curve
    plot(xData, yData,'g-');
    
    hold off;
    title(strcat(chanDesc,' vs. Time'));
    xlabel(xLabel);
    ylabel(yLabel);
    
    %---------------------------------
    %Force curves against distance (separation)
    f = figure();
    movegui(f,'northeast');
    hold on;
    
    %plot against distance (separation)for 3 corner pixels
    %CreateForceVolumeForceCurveZplot arguments:
    %   first: pixel location
    %   second: units
    %   third: 0 = z; 1 = separation
    
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveZplot(1, NSMU.FORCE, 1); %bottom left pixel    
    plot(xTrace, yTrace,'b-');
    plot(xRetrace, yRetrace,'r-');

    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveZplot(forVolPixel, NSMU.FORCE, 1); %bottom right pixel
    plot(xTrace, yTrace,'c-');
    plot(xRetrace, yRetrace,'m-');
    
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveZplot(NumberOfCurves, NSMU.FORCE, 1); %top right pixel
    plot(xTrace, yTrace,'g-');
    plot(xRetrace, yRetrace,'y-');
    
    %hold off;
    title(strcat('Force vs. Separation'));
    xlabel(xLabel);
    ylabel(yLabel);
    
    %close file
    NSMU.Close();
end

function NSMatlabForceVolumeHoldExample()
   position = {'northwest', 'north', 'northeast'};
    NSMU = NSMatlabUtilities();
   
    %open a force volume file which contains hold segments
    NSMU.Open(which('FVHold.spm'));
    
     %get number of image pixels & number of force curves in each scan line
    [imagePixel, forVolPixel] = NSMU.GetForceVolumeScanLinePixels(); 
    NumberOfCurves = NSMU.GetNumberOfForceCurves();
    
    %---------------------------------
    %Display image
    f = figure();
    movegui(f, position{1});
    
    %Get FV Image Data
    [data, scaleUnit, dataTypeDesc] = NSMU.GetForceVolumeImageData(NSMU.METRIC);
    
    image(flipud(data),'CDataMapping','scaled');
    set(gca,'YDir','normal');
    axis('tight', 'square'); 
    colormap('Copper');
    hold on;
    plot(1, 1, 's', 'MarkerSize', 30,'MarkerEdgeColor','b', 'MarkerFaceColor', 'b')   
    plot(imagePixel, 1, 's', 'MarkerSize', 30,'MarkerEdgeColor','c', 'MarkerFaceColor','c')   
    plot(imagePixel, imagePixel, 's', 'MarkerSize', 30,'MarkerEdgeColor','g', 'MarkerFaceColor','g')   


    axis('tight', 'square'); 
    %colorbar();
    
    title(strcat('Force Volume',{' '}, dataTypeDesc, ' Image')); 
    xLabel = NSMU.GetScanSizeLabel();
    xlabel(xLabel);
    
    %---------------------------------
    %Plot hold data for 2 channels
    numChannels = NSMU.GetNumberOfChannels();
    firstChan = 2; %note: channel 1 is the image data
    lastChan  = min(numChannels, 3); % only plot up to 2 channels

    
    %cycle through channels
    for ichan = firstChan:lastChan
        [chanDesc] = NSMU.GetDataTypeDesc(ichan);
        f = figure();
        movegui(f,position{ichan});
        hold on;
        
        %x spacing based on hold time and # hold pts
        holdTimeSecs = NSMU.GetForceHoldTime(ichan);  
        xAxis = linspace(0, holdTimeSecs,  NSMU.GetNumberOfHoldPoints(ichan))';
        
        %now plot hold data for 3 corner pts      
        [rawData, scaleUnit] = NSMU.GetForceVolumeHoldData(ichan, 1, NSMU.METRIC); %bottom left curve
        plot(xAxis, rawData, 'b-');

        [rawData, scaleUnit] = NSMU.GetForceVolumeHoldData(ichan, forVolPixel, NSMU.METRIC); %bottom right curve
        plot(xAxis, rawData, 'c-');

        [rawData, scaleUnit] = NSMU.GetForceVolumeHoldData(ichan, NumberOfCurves, NSMU.METRIC); %top right curve
        plot(xAxis, rawData, 'g-');
        
        title (strcat('FV Hold Data:',{' '}, chanDesc, ' vs. Time')); 
        xlabel('Time (secs)');
        ylabel(strcat(chanDesc, ' (', scaleUnit, ')'));
    end
    
    %--------------------------------------------------
    %put force curves centered and below the image and hold plots
    f = gcf;
    posLast = get(f, 'Position');
    
    f = figure();
    movegui(f,'north');
    pos = get(f, 'Position');
    set(f, 'Position', pos + [0 -(posLast(4)+100) 0 0 ]);
    hold on;
    
  
    %Now plot force vs separaton for same 3 points
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveZplot(1, NSMU.FORCE, 1); %bottom left pixel    
    plot(xTrace, yTrace,'b-');
    plot(xRetrace, yRetrace,'r-');

    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveZplot(forVolPixel, NSMU.FORCE, 1); %bottom right pixel
    plot(xTrace, yTrace,'c-');
    plot(xRetrace, yRetrace,'m-');
    
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreateForceVolumeForceCurveZplot(NumberOfCurves, NSMU.FORCE, 1); %top right pixel
    plot(xTrace, yTrace,'g-');
    plot(xRetrace, yRetrace,'y-');
    
    title(strcat('Force vs. Separation'));
    xlabel(xLabel);
    ylabel(yLabel);

     
    %close file
    NSMU.Close();
end

function NSMatlabPeakForceCaptureExample1()
    NSMU = NSMatlabUtilities();
    
    %open a peak force capture file
    NSMU.Open(which('PeakForce.pfc'));
 
    %get number of image pixels & number of PF curves in each scan line
    [imagePixel, forVolPixel] = NSMU.GetForceVolumeScanLinePixels();      
    NumberOfCurves = NSMU.GetNumberOfForceCurves(); %Note: this should be equal to forVolPixel*forVolPixel
    
    %---------------------------------
    %Display image
    f = figure();
    movegui(f,'northwest');
     
    [data, scaleUnit, dataTypeDesc] = NSMU.GetPeakForceCaptureImageData(NSMU.METRIC);
    image(flipud(data),'CDataMapping','scaled');
    set(gca,'YDir','normal');
    axis('tight', 'square'); 
    colormap('Copper');
    hold on;
    plot(1, 1, 's', 'MarkerSize', 3,'MarkerEdgeColor','b', 'MarkerFaceColor', 'b')   
    plot(imagePixel/2, imagePixel/2, 's', 'MarkerSize', 3,'MarkerEdgeColor','c', 'MarkerFaceColor','c')   
    plot(imagePixel, imagePixel, 's', 'MarkerSize', 3,'MarkerEdgeColor','g', 'MarkerFaceColor','g')   

    colorbar();
    
    title(strcat('Peak Force',{' '}, dataTypeDesc, ' Image')); 
    xLabel = NSMU.GetScanSizeLabel();
    xlabel(xLabel);
   
    %------------------------------------------------------------------
    %PeakForce Force Curves against time
    f = figure();
    movegui(f,'north');
    hold on;
   
    [chanDesc] = NSMU.GetDataTypeDesc(2); %Chan 1 is Image channel, so grab force curve data type from chan 2  

    [xData, yData, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveTimePlot(1, NSMU.METRIC); %bottom left curve
    plot(xData, yData,'b-');

    [xData, yData, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveTimePlot(NumberOfCurves/2, NSMU.METRIC); %center curve
    plot(xData, yData,'c-');

    [xData, yData, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveTimePlot(NumberOfCurves, NSMU.METRIC); %top right curve
    plot(xData, yData,'g-');
    
    title(strcat(chanDesc,' vs. Time'));
    xlabel(xLabel);
    ylabel(yLabel);
    
    %-------------------------------------------------------
    %PeakForce Force Curves against distance (separation)
    f = figure();
    movegui(f,'northeast');
    hold on;
    
    %plot against distance (separation)for 3 corner pixels
    %CreatePeakForceForceCurveZplot arguments:
    %   first: pixel location
    %   second: units
    %   third: 0 = z; 1 = separation
    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveZplot(1, NSMU.METRIC, 1); %bottom left curve
    plot(xTrace, yTrace,'b-');
    plot(xRetrace, yRetrace,'r-');

    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveZplot(NumberOfCurves/2, NSMU.METRIC, 1); %center curve
    plot(xTrace, yTrace,'c-');
    plot(xRetrace, yRetrace,'m-');

    [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveZplot(NumberOfCurves, NSMU.METRIC, 1); %top right curve
    plot(xTrace, yTrace,'g-');
    plot(xRetrace, yRetrace,'y-');
    
    title(strcat(chanDesc,' vs. Separation'));
    xlabel(xLabel);
    ylabel(yLabel);

    %close file
    NSMU.Close();
end

function Modulus = NSMatlabPeakForceCaptureExample2()
   
    NSMU = NSMatlabUtilities();

    %open a peak force capture file
    NSMU.Open(which('PeakForce.pfc'));
    
    %calculate young's modulus for every 100th force curve
    NumberOfCurves = NSMU.GetNumberOfForceCurves();
    PR = NSMU.GetPoissonRatio();
    TR = NSMU.GetTipRadius();
    
    for i = 1:100:NumberOfCurves
        %get F vs tip-sample separation plot of curve i
        [xTrace, xRetrace, yTrace, yRetrace, xLabel, yLabel] = NSMU.CreatePeakForceForceCurveZplot(i, NSMU.METRIC, 1);
        contactPointIndex = FindContactPoint(xRetrace, yRetrace);
        [regionBottom, regionTop] = ComputeContactRegionBounds(xRetrace, yRetrace, contactPointIndex, 10, 70);
        [index1, index2] = ComputeMarkers(xRetrace, yRetrace, regionTop, regionBottom);
        K = ExponentialFit(xRetrace, yRetrace, index1, index2, contactPointIndex);
        Modulus = GetYoungsModulus(K, PR, TR);
        disp(['Curve # ',num2str(i),': Modulus = ', num2str(Modulus)]);
    end

	
	%close file
    NSMU.Close();
end


function NSMatlabHSDCExample()  %%open a HSDC file
    NSMU = NSMatlabUtilities();
    
    %open a HSDC file
    NSMU.Open(which('HSDC.hsdc'));
 
    numChan = NSMU.GetNumberOfChannels();
    %--------------------------------
    %Plot HSDC Data
    [rate] = NSMU.GetHsdcRate(1);
    deltaT = 1;
    if rate ~=0
        deltaT = 1000/rate;
    end
   
    for ichan = 1:min(numChan, 3)
        [data, scale_units, type_desc] = NSMU.GetHSDCData(ichan, NSMU.METRIC);
        npts = numel(data);
        xAxis = linspace(0, deltaT*npts,  npts);
        f(ichan) = figure();
        
        %stretch horizontal axis and stack plots vertically
        if (ichan == 1)
            movegui(f(ichan),'north');
            pos = get(f(ichan),'Position');
            set(f(ichan),'Position', pos + [pos(3)/2-800 0 1600-pos(3) 0]);
        else
            pos = get(f(ichan-1),'Position');
            set(f(ichan), 'Position', pos + [0, - (pos(4) + 100), 0, 0]);
        end

        plot(xAxis, data);

        title(strcat('HSDC:',{' '}, type_desc));
        xlabel('Time (msec)');
        ylabel(strcat(type_desc, ' (', scale_units,')'));
    end;
    NSMU.Close();
end

function NSMatlabImageExample()
    NSMU = NSMatlabUtilities();

    %open a NanoScope image file   
    NSMU.Open(which('Image.spm'));
    
    numChan = NSMU.GetNumberOfChannels();
    
    f = figure();
    movegui(f,'north');
    pos = get(f,'Position');
    set(f,'Position', pos + [-150 0 300 0]);
    
    %-------------------------------------------
    %Display Image for each channel
    for ichan = 1:numChan
        
        %Get data and some descriptive info
        [data, scale_units, type_desc] = NSMU.GetImageData(ichan, NSMU.METRIC);
        lineDir = NSMU.GetLineDirection(ichan);
        scanLine = NSMU.GetScanLine(ichan);
        AspectRatio = NSMU.GetImageAspectRatio(ichan);
        
        %compute planefit coefficients and display on command line
        [a, b, c, fitTypeStr] = NSMU.GetPlanefitSettings(ichan);
        disp(['Chan # ',num2str(ichan),': Aspect Ratio = ',num2str(AspectRatio),...
            ', PlaneFit Coeffs = (',num2str(a),',',num2str(b),',',num2str(c),')']);
       
        sp = subplot(1,double(numChan),double(ichan));

        %this code spaces things nicely, but I got here iteratively, not
        %logically :=}
        pos = get(sp, 'Position'); % gives the position of current sub-plot
        if ichan == 1
            new_pos = pos + [-.04 0 .02 .02]; 
        elseif ichan == 2
            new_pos = pos + [-.015 0 .02 .02];
        elseif ichan == 3
            new_pos = pos + [0 0 .02 .02];
        end        
        set(sp, 'Position',new_pos );
        
        % now plot and annotate
        image(flipud(data),'CDataMapping','scaled');
        set(gca,'YDir','normal');
        axis('tight', 'square'); 
        
        title(type_desc)  
        xlabel(strcat(lineDir,'; ',scanLine));
        axis('tight', 'square');
        drawnow;
    end

    NSMU.Close();
end

function NSMatlabScriptExample(allSegs)
   position = {'northwest', 'north', 'northeast'};
   NSMU = NSMatlabUtilities();
   
    %open a NanoScope script data file   
    NSMU.Open(which('Script.spm'));
    
    numChan = NSMU.GetNumberOfChannels();
    [nSegments, sizeSegs, descripSegs, ~] = NSMU.GetScriptSegmentInfo();
    
    if (allSegs)
        segNum = 0; %use segNum = 0 to get all segments
    else
        segToPlot = 6;                   %arbitrarily plot seg 6 (or last if few than 6)
        segNum = min(segToPlot, nSegments); 
    end
    
    numChan = min(numChan, 3); %only plot up to 1st 3 channels

    for i = 1:numChan
          [xData, yData, scaleUnit, dataTypeDesc] = NSMU.GetScriptSegmentData(i,segNum, NSMU.METRIC);
          f = figure();
          movegui(f,position{i}); 
          hold on;
          
          plot(xData, yData);
          yval = ylim;
          xPos = sizeSegs(1)+ 1;
           
          %plot segment dividers of more than 1 segment
          if (allSegs && nSegments > 1)
               for j = 2:nSegments         
                   line([xData(xPos) xData(xPos)],yval,'Color', [1, 0,0]);
                   xPos = xPos+sizeSegs(j);
               end
          end
          if (allSegs)
              Title = strcat({'Script '}, dataTypeDesc, {' - '},num2str(nSegments),' Segments');
          else
              Title = strcat({'Script '}, dataTypeDesc, ' Segment #',num2str(segNum),{': '}, descripSegs(segNum));
          end
          
          title(Title);
          ylabel(strcat(dataTypeDesc, ' (', scaleUnit,')'));
          xlabel('Time (secs)');
    end
    
    % Show segment names in command window if plotting all segments
    if (allSegs && nSegments > 0)
        for j = 1: nSegments
          fprintf('Seg # %s : %s\n' ,num2str(j),char(descripSegs(j)));
        end
    end
    NSMU.Close();
end

function NSMatlabImageNanoDriveExample()   %%open a spm lab file
    NSMU = NSMatlabUtilities();
    
    %open a Nanodrive data file   
    NSMU.Open(which('Nanodrive.flt'));
    
    channels = NSMU.GetNumberOfChannels();
    %[data, scale_units, type_desc] = NSMU.GetImageData(1, NSMU.RAW);
    [data, scale_units, type_desc] = NSMU.GetImageData(1, NSMU.METRIC);
    %[data, scale_units, type_desc] = NSMU.GetImageData(1, NSMU.VOLTS);
    xLabel = NSMU.GetScanSizeLabel();
    Height = flipud(data);
    figure();
    surface(Height, 'LineStyle','none');
    axis('tight', 'square');
    colormap('Copper');
    %colorbar();
    title('NanoDrive');
    xlabel(xLabel);
    NSMU.Close();
end

function E = GetYoungsModulus(K, PoissonRatio, TipRadius)
    %Returns YoungsModulus, E in MPa 
    %Use Hertz sphere model to calculate Young's Modulus.
    PoissonRationSqrd = PoissonRatio^2;
    sqrtTipRadius = sqrt(TipRadius);
    %Hertz model: K = 4/3 * E/(1-PR^2) * R ^ 1/2
    E = (1 - PoissonRationSqrd) * .75 * K/sqrtTipRadius;
end
 
function K = ExponentialFit (xData, yData, index1, index2, contactPointIndex)
    K = 0;
    xSize = max(size(xData));
    ySize = max(size(yData));
    if xSize ~= ySize
      error('xData must be the same size as yData.')
    end
    nBins = abs(index2 - index1) + 1;
    startIndex = min(index1,index2);
    endIndex = max(index1,index2);
    %add the contact regions to the vectors
    fitXData = xData(startIndex:(endIndex - 1));
    fitYData = yData(startIndex:(endIndex - 1));
    %add the contact point to the front of the vectors
    fitXData = [xData(contactPointIndex); fitXData];
    fitYData = [yData(contactPointIndex); fitYData];
    %transfer the data so x=0 is the first data point
    x0 = fitXData(1);
    x1 = fitXData(nBins);
    scale = abs(x1 - x0)/(x1 - x0);
    yMin = fitYData(1);
    %not flipped
    if fitYData(1) <= fitYData(nBins)
        fitXData = (fitXData - x0) * scale;
    %flipped
    else
        yMin = fitYData(nBins);
        fitXData = (x1 - fitXData)*scale;
    end
    %get y in PN
    fitYData = (fitYData - yMin) * 1000;
    %get the first guess, K = mean(F(x)/x^E)
    n = 0;
    for i=1:nBins
        if fitXData(i)>0 && fitYData(i)>=0
            K = K + fitYData(i)/fitXData(i)^1.5;
            n = n+1;
        end
    end
    if n > 0
        K = K /n;
    end
end

function [index1, index2] = ComputeMarkers(xData, yData, regionTop, regionBottom)
    [index1, index2] = deal(-1);
    nPts = max(size(yData));
    step = 1;
    startIndex = 1;
    endIndex = nPts;
    %if it's reverse index
    if xData(1) > xData(nPts)
        startIndex = nPts;
        endIndex = 1;
        step = -1;
    end
    i = startIndex;
    while i~=endIndex
        if (index1 == -1)
            if (yData(i) <= regionTop)
                index1 = i;
            end
        elseif (yData(i) <= regionBottom)
            index2 = i - step;
            break;
        end
        i = i+ step;
    end
end
function [regionBottom, regionTop] = ComputeContactRegionBounds(xData, yData, contactPointIndex, minForcePercent, maxForcePercent)

    [curveStartIndex, curveEndIndex] = deal(0);
    xSize = max(size(xData));
    ySize = max(size(yData));
   
    if xData(1) < xData(xSize)
        curveStartIndex = xSize;
        curveEndIndex = 1;
    else
        curveStartIndex = 1;
        curveEndIndex = xSize;
    end
    maxRegion = yData(curveEndIndex);
    minRegion = yData(contactPointIndex);
    regionBottom = (maxRegion - minRegion) * minForcePercent / 100 + minRegion;
    regionTop = (maxRegion - minRegion) * maxForcePercent / 100 + minRegion;
end

function [contactPointIndex] = FindContactPoint(xData, yData)
% Finds intersection point of the curve and line connected the first and last point. 
% curveStartIndex, contactPointIndex andcurveEndIndex are 0 if no intersection exists.
%
% Example

    curveStartIndex = 0;
    contactPointIndex = 0;
    curveEndIndex = 0;
    xSize = max(size(xData));
    ySize = max(size(yData));
    %if(xSize == ySize)

    %Method for contact point is subtract the line connected the first and last point from all points in the curve, and use the lowest point
    slope = (yData(ySize) - yData(1)) / (xData(xSize) - xData(1));
    minY = 0;
    for i = 1:ySize
        yVal = yData(i) - slope * xData(i);
        if (i == 1 || yVal < minY )
            minY = yVal;
            contactPointIndex = i;
        end
    end
    %Determine direction of curve. Method assumes end of the contact region is higher that the non-contact region
    if (yData(1)> yData(ySize))
        curveStartIndex = ySize;
        curveEndIndex = 1;
    else
        curveStartIndex = 1;
        curveEndIndex = ySize;
    end;
    %Method is find highest point after contact point
    if curveEndIndex > contactPointIndex
        increment = 1;
    else
        increment = -1;
    end
    maxY = 0;
    i = contactPointIndex + increment;
    while i * increment <= curveEndIndex * increment
        if yData(i) > maxY
            maxY = yData(i);
        end
        i = i + increment;
    end
    targetMaxY = (maxY - yData(contactPointIndex)) + yData(contactPointIndex);
    maxIndex = contactPointIndex;
    i= contactPointIndex + increment;
    while i * increment <= curveEndIndex * increment
        if (yData(i) > targetMaxY)
            break;
        end
        maxIndex = i;
        i = i + increment;
    end
    curveEndIndex = maxIndex;
end


