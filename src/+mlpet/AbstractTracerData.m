classdef (Abstract) AbstractTracerData < handle & mlpet.ITracerDosing & mlpet.IDecaying & mlkinetics.ITiming
	%% ABSTRACTTRACERDATA is an AbstractProduct in an abstract factory pattern.
    %  For concrete subclasses see also:  mlcapintec.CapracData, mlswisstrace.TwiliteData, mlpet.BloodSuckerData, 
    %  mlsiemens.BiographMMRData, mlsiemens.EcatExactHRPlusData, and similarly named classes for project packages such
    %  as mlpowers, mlarbelaez, mlraichle.

	%  $Revision$
 	%  was created 17-Oct-2018 15:54:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		
        %% mlpet.ITracerDosing
        
 		sessionIdentifier % unambiguously identifies the measurement session
        tracer
        dose
        doseUnits
        doseAdminDatetime % synchronized to an NTS
        comments
        
        %% mlpet.IDecaying
        
        activities
        activityUnits
 		isdecaying
        halflife
        isotope
        zerotime
        zerodatetime 
        
        %% mlkinetics.ITiming
        
        taus          % frame durations,    length() == length(times)  
        times         % frame starts
        time0         % selects time window; >= this.time(1)                
        timeF         % selects time window; <= this.times(end)
        timeInterpolants
        timesMid      % frame middle times, length() == length(times)
        timeMid0      % frame middle time0
        timeMidF      % frame middle timeF
        timeMidInterpolants
        indices       % of times
        index0        % index of time0
        indexF        % index of timeF
        datetime0     % datetime of this.time0
        datetimeF     % datetime of this.timeF
        dt            % for timeInterpolants; <= min(taus)/2 
        
        %% 
        
        activityInterpolants
        activityMidpointInterpolants
    end
    
    methods (Abstract, Static)
        this = CreateFromScanId(varargin)
    end

	methods 
        
        %% GET
        
        
        
        %% 
        
        function a = activityIntegral(this, varargin)
            error('mlpet:NotImplementedError');
        end
        function d = datetime(this)
            error('mlpet:NotImplementedError');
        end
        function d = duration(this) % timeF  - time0, in sec
            d = seconds(this.timeF - this.time0);
        end
        function i = indexOfInflow(this)
            error('mlpet:NotImplementedError');
        end
        function i = indexOfOutflow(this)
            error('mlpet:NotImplementedError');
        end
        function l = length(this)   % indexF - index0 + 1
            l = this.indexF - this.index0 + 1;
        end
        function h = plot(this)
            error('mlpet:NotImplementedError');
        end
        function     shiftWorldline(this)
            error('mlpet:NotImplementedError');
        end
		  
 		function this = AbstractTracerData(varargin)
 			%% ABSTRACTTRACERDATA
 			%  @param .
            
            ip = inputParser;
            addRequired(ip, 'scid', @(x) isa(x, 'mlpet.IScanIdentifier'));
            parse(ip, varargin{:});
            import mlpet.*;
            
%% Move to concrete TracerData.
%             this.tracerDosing_ = TracerDosing.CreateFromScanId(varargin{:});
%             this.timing_ = Timing.CreateFromScanId(varargin{:});
%             this.decay_ = Decay.CreateFromScanId(varargin{:});

 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        tracerDosing_
        timing_
        decay_
        
        activitiesCache_
        activityInterpolantsCache_
        activityMidpointInterpolantsCache_
        datetimeCache_
        tausCache_
        timeInterpolantsCache_
        timeMidpointInterpolantsCache_
        timeMidpointsCache_
        timesCache_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

