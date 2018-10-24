classdef (Abstract) TracerDosing < handle & mlpet.ITracerDosing
	%% TRACERDOSING  

	%  $Revision$
 	%  was created 17-Oct-2018 16:17:28 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.

	properties (Dependent)
 		sessionIdentifier % unambiguously defines the measurement session
        tracer
        dose
        doseUnits
        doseAdminDatetime % synchronized to an NTS
        comments
    end
    
    methods (Abstract, Static)
        this = CreateFromScanId(varargin)
    end

	methods 
		  
 		function this = TracerDosing(varargin)
 			%% TRACERDOSING
            %  @param sessionId is mlpipeline.ISessionIdentifier
 			%  @param tracer is char.
            %  @param dose is numeric.
            %  @param doseUnits is char, default := 'mCi'.
            %  @param adminTime is datetime measured with a local clock device which may not be synchronized to an NTS.
            %  @param clockOffset is duration for discrepency of the local clock to an NTS.
            %  @param comments is char.
            
 			ip = inputParser;
            addParameter(ip, 'sessionId', [], @(x) isa(x, 'mlpipeline.ISessionIdentifier'));
            addParameter(ip, 'tracer', '', @ischar);
            addParameter(ip, 'dose', nan, @isnumeric);
            addParameter(ip, 'doseUnits', 'mCi', @ischar);
            addParameter(ip, 'doseAdminDatetime', NaT, @isdatetime);
            addParameter(ip, 'comments', '', @ischar);
            parse(ip, varargin{:});
            this.sessionId_         = ip.Results.sessionId;
            this.tracer_            = ip.Results.tracer;       
            this.dose_              = ip.Results.dose;     
            this.doseUnits_         = ip.Results.doseUnits;      
            this.doseAdminDatetime_ = ip.Results.doseAdminDatetime;
            this.comments_          = ip.Results.comments;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
 		sessionId_
        tracer_
        dose_
        doseUnits_
        doseAdminDatetime_
        comments_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

