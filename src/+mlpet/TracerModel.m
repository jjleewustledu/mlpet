classdef TracerModel 
	%% TRACERMODEL  
    %  See also:
    %  mlswisstrace.{CatheterModel2,Munk2008,TwiliteCatheterCalibration}
    %  mlswisstrace_unittest.Test_Catheter_DT20190930

	%  $Revision$
 	%  was created 27-Jan-2020 17:57:46 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        measurementTime_
        radionuclide_
        specificActivity_
 	end

	methods 
        
        function c = twiliteCounts(this, varargin)
            sa = this.specificActivity(varargin{:});
            
            % well-counter Bq/mL to Twilite cps, by regression with catheter adjustment
            c = 0.0046.*sa - 30.302;
        end
        function sa = specificActivity(this, varargin)
            ip = inputParser;
            addOptional(ip, 'dt', this.measurementTime_, @isdatetime)
            parse(ip, varargin{:})
            
            dseconds = seconds(ip.Results.dt - this.measurementTime_);
            sa = this.specificActivity_ ./ 2.^(dseconds/this.radionuclide_.halflife);
        end
		  
 		function this = TracerModel(varargin)
 			%% TRACERMODEL
 			%  @param activity is from Caprac well-counter

 			ip = inputParser;
            addParameter(ip, 'radionuclide', 'fdg', @ischar)
            addParameter(ip, 'activity', [], @isnumeric)
            addParameter(ip, 'activityUnits', 'Bq/mL', @ischar)
            addParameter(ip, 'measurementTime', NaT, @isdatetime)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.radionuclide_ = mlpet.Radionuclides(ipr.radionuclide);            
            switch ipr.activityUnits
                case 'Bq/mL'
                    this.specificActivity_ = ipr.activity;
                otherwise
                    error('mlpet:NotImplementedError', ...
                        'TracerModel.ipr.activityUnits->%s', ipr.activityUnits)
            end
            this.measurementTime_ = ipr.measurementTime;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

