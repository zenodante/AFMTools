classdef cAFMImage
    %cAFMImage 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        FileName
        NumberOfChannels
        ImageAspectRatio
        LineDirection
        ScanSize
        ScanSizeLabel
        PlanefitSettings
        ScanLine
        SamplesPerLine
        NumberOfLines
        Data
        DataType
        ChannelNames
        XSize
        YSize
    end
    properties (Dependent)
    	%Area
    end
    
    methods
        function obj = cAFMImage(FileName,varargin)
            NSMU = NSMatlabUtilities();
            try
                NSMU.Open(FileName);
            catch
                warning('file IO error.');
                return;
            end
            vars_list = {'Channels' 'DataType'};
            sParameter = NSVarProcess(varargin, vars_list);
            
            %get the source file name
            obj.FileName = FileName;   
            
            %how many channels in this image file
            Channels = NSMU.GetNumberOfChannels();
            % if user specifies the channels
            if ~isnan(sParameter.Channels)
                obj.NumberOfChannels = length(sParameter.Channels);
                %ChannelsIndex is the index for each readin data channel in
                %source file
                ChannelsIndex = sParameter.Channels;
            else  %if user doesn't specify the channels
                obj.NumberOfChannels = Channels;
                ChannelsIndex = [1:Channels];
            end
            %get the aspect ratio for each channel
           
            
            %get the aspect ratio for each channel   
            obj.ImageAspectRatio = NSMU.GetImageAspectRatio(1);
            %get scan size
            obj.ScanSize = NSMU.GetScanSize(1);
            %scan size label    
            obj.ScanSizeLabel=NSMU.GetScanSizeLabel();
            %x,y size
            obj.XSize = obj.ScanSize;
            obj.YSize = obj.ScanSize/obj.ImageAspectRatio;
            
            for i=1:obj.NumberOfChannels
            
            %get the channel line direction    
                obj.LineDirection{i} = NSMU.GetLineDirection(ChannelsIndex(i));
            %get planefit settings ??not understand...
                obj.PlanefitSettings(i) = NSMU.GetPlanefitSettings(ChannelsIndex(i));
                obj.ScanLine{i} = NSMU.GetScanLine(ChannelsIndex(i));
                obj.ChannelNames{i}=NSMU.GetDataTypeDesc(ChannelsIndex(i));
                obj.SamplesPerLine(i)=NSMU.GetSamplesPerLine(ChannelsIndex(i));
                obj.NumberOfLines(i)=NSMU.GetNumberOfLines(ChannelsIndex(i));
                %if user specifies the data type of the channel
                if ~isempty(sParameter.DataType)  
                    if strcmp(sParameter.DataType{i},'RAW')
                        obj.Data{i}=NSMU.GetImageData(ChannelsIndex(i),NSMU.RAW);
                    elseif strcmp(sParameter.DataType{i},'VOLTS') 
                        obj.Data{i}=NSMU.GetImageData(ChannelsIndex(i),NSMU.VOLTS);
                    else
                        obj.Data{i}=NSMU.GetImageData(ChannelsIndex(i),NSMU.METRIC);
                    end
                    obj.DataType{i}= sParameter.DataType{i};
                else %user didn't specify the data type
                    obj.Data{i}=NSMU.GetImageData(ChannelsIndex(i),NSMU.METRIC);
                    obj.DataType{i}= 'METRIC';
                end
            end
            
            NSMU.Close();
          
            
        end
        
        %function val = get.Area(obj)
        %	val = obj.x_size * obj.y_size;
        %end
    end
    
end

