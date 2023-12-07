classdef (Abstract) AbstractScannerDevice < handle & mlpet.AbstractDevice
    %% line1
    %  line2
    %  
    %  Created 27-Nov-2023 15:11:58 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
	properties (Dependent)
        invEfficiency
    end
    
	methods %% GET     
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
    end

    methods
        function a = activity(this, varargin)
            %% is calibrated to ref-source; Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.data_.activity(varargin{:})*this.invEfficiency_;
        end
        function a = activityDensity(this, varargin)
            %% is calibrated to ref-source; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.data_.activityDensity(varargin{:})*this.invEfficiency_;
        end
        function that = blurred(this, varargin)
            that = copy(this);
            that.data_ = that.data_.blurred(varargin{:});
        end
        function c = countRate(this, varargin)
            %% has no calibrations; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.            
            
            c = this.data_.countRate(varargin{:});
        end      
        function that = masked(this, varargin)
            that = copy(this);
            that.data_ = that.data_.masked(varargin{:});
        end
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetime', 'datetimesMid', 'times', 'indices'}
            %  @param optional ordinate in {'countRate', 'activity', 'actvityDensity', 'this.activityDensity(''volumeAveraged'', true)'}.
            
            ip = inputParser;
            addOptional(ip, 'abscissa', 'this.datetimesMid', @ischar)
            addOptional(ip, 'ordinate', 'this.activityDensity(''volumeAveraged'', true)', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if length(eval(ipr.abscissa)) < 100
                marks = ':o';
            else
                marks = '.';                
            end
            
            h = figure;
            plot(eval(ipr.abscissa), eval(ipr.ordinate), marks);
            switch strtok(ipr.abscissa, '(')
                case 'this.times'
                    xlabel('time / s')
                otherwise
            end
            switch strtok(ipr.ordinate, '(')
                case 'this.countRate'
                    ylabel('count rate / cps')
                case 'this.activity'
                    ylabel('activity / Bq')
                case 'this.activityDensity'
                    ylabel('activity density / (Bq/mL)')
                otherwise
            end
            title(sprintf('%s.plot(%s)', class(this), this.data_.tracer))
        end 
        function that = timeAveraged(this, varargin)
            that = copy(this);
            that.data_ = that.data_.timeAveraged(varargin{:});
        end
        function that = volumeAveraged(this, varargin)
            that = copy(this);
            that.data_ = that.data_.volumeAveraged(varargin{:});
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
    end
    
    methods (Access = protected)
        function this = AbstractScannerDevice(varargin)
 			this = this@mlpet.AbstractDevice(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
