classdef TracerDirector 
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties (Constant)
        NUM_VISITS = 3
    end
    
	properties (Dependent)
        builder
        sessionData
        studyData
    end
    
    methods (Static)
        function this = constructRemotely(varargin)
            %% CONSTRUCTREMOTELY is a creator/producer:  TracerDirector factoryMethod -> TracerDirector.
            %  @param sessionData is an mlpipeline.SessionData.
            %  @param factoryMethod is from some TracerDirector.
            %  @param factorArgs is cell array for factoryMethod.
            %  @return this is the TracerDirector instance deployed which can continue management of its assigned
            %  builders.
            
            ip = inputParser;
            addRequired( ip, 'chpc',            @(x) isa(x, 'mldistcomp.CHPC'));
            addParameter(ip, 'factoryMethod',   @(x) isa(x, 'function_handle'));
            addParameter(ip, 'factoryArgs', {}, @iscell);
            addParameter(ip, 'nArgout', 0, @isnumeric);
            parse(ip, varargin{:});
            chpc = ip.Results.chpc;
            
            chpc = chpc.pushData;
            chpc = chpc.runSerialProgram(ip.Results.factoryMethod, ip.Results.factoryArgs, ip.Results.nArgout);
            %chpc = chpc.pullData;
            this = chpc.theDeployedDirector; % TracerDirector instance deployed by factoryMethod
            assert(isa(this, 'mlpet.TracerDirector'));
        end
        function this = pullFromRemote(varargin)
            
            ip = inputParser;
            addRequired( ip, 'chpc',            @(x) isa(x, 'mldistcomp.CHPC'));
            parse(ip, varargin{:});
            chpc = ip.Results.chpc;
            
            chpc = chpc.pullData;
            this = chpc.theDeployedDirector; % TracerDirector instance deployed by factoryMethod
            assert(isa(this, 'mlpet.TracerDirector'));
        end
    end
    
    methods 
        
        %% GET/SET
        
        function g = get.builder(this)
            g = this.builder_;
        end
        function g = get.sessionData(this)
            g = this.builder_.sessionData;
        end
        function g = get.studyData(this)
            g = this.builder_.sessionData.studyData;
        end
        
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.builder_.sessionData = s;
        end
        
        %%        
               
        function obj = getResult(this)
            obj = this.builder_.product;
        end
        function tf = isJSReconComplete(~)
            tf = true;
        end
        function this = locallyStageTracer(this)
            this.builder_.vendorSupport = mlsiemens.MMRBuilder('sessionData', this.sessionData);
            this.builder_ = this.builder_.locallyStageTracer;
        end
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  @param builder must be an mlpet.TracerBuilder
            
            ip = inputParser;
            addRequired(ip, 'builder', @(x) isa(x, 'mlpet.TracerBuilder'));
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
        end
 	end 

    
    %% PROTECTED
    
    properties (Access = protected)
        builder_
    end
    
    methods (Access = protected)
        function this = instanceConstructAC(this)
            
            this.builder_ = this.builder_.reconstituteFramesAC;

            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;
        end
        function this = instanceConstructNAC(this)
            
            this.builder_       = this.builder_.locallyStageTracer;            
            this.builder_       = this.builder_.partitionMonolith;
            [this.builder_,multiEpochOfSummed,reconstitutedSummed] = this.builder_.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectModalities;             
            this.builder_       = reconstitutedSummed.motionUncorrectUmap(multiEpochOfSummed);
        end
        function those = instanceConstructRemotely(this, varargin)
            %  @param sessionData   is a function_handle to an mlpipeline.SessionData ctor.
            %  @param construct     is a function_handle to some implemented factory method.  
            %  @param named dirTool is an mlsystem.DirTool.
            %  @param named distcompHost is the hostname or distcomp profile.
            %  @return this, a cell-array of TracerDirector instances of size N{sessions} x NUM_VISITS.
            
            ip = inputParser;
            addRequired( ip, 'sessionData',  @(x) isa(x, 'function_handle'));
            addRequired( ip, 'construct',    @(x) isa(x, 'function_handle'));
            addParameter(ip, 'nArgout', 0,   @isnumeric);
            addParameter(ip, 'dirTool',      @(x) isa(x, 'mlsystem.DirTool'));
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            parse(ip, varargin{:});
            
            import mlpet.*;
            those = {};
            for d = 1:length(ip.Results.dirTool.fqdns)
                for v = 1:TracerDirector.NUM_VISITS
                    try
                        sessd = ip.Results.sessionData( ...
                            'studyData',   this.studyData, ...
                            'sessionPath', ip.Results.dirTool.fqdns{d}, ...
                            'vnumber',     v, ...
                            'tracer',      this.sessionData.tracer);
                        if (~isdir(sessd.vLocation))
                            continue
                        end
                        this.sessionData = sessd;
                        this = this.locallyStageTracer;
                        csessd = ip.Results.sessionData( ...
                            'studyData',   this.studyData, ...
                            'sessionPath', mldistcomp.CHPC.chpcSubjectsDir(ip.Results.dirTool.fqdns{d}), ...
                            'vnumber',     v, ...
                            'tracer',      this.sessionData.tracer);
                        those{d,v} = TracerDirector.constructRemotely( ...
                            CHPC4TracerDirector(this, 'distcompHost', ip.Results.distcompHost, 'sessionData', sessd), ...
                            'factoryMethod', ip.Results.construct, ...
                            'factoryArgs', {'sessionData', csessd}, ...
                            'nArgout', ip.Results.nArgout);  %#ok<AGROW>
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function those = instancePullFromRemote(this, varargin)
            %  @param sessionData   is a function_handle to an mlpipeline.SessionData ctor.
            %  @param construct     is a function_handle to some implemented factory method.  
            %  @param named dirTool is an mlsystem.DirTool.
            %  @param named distcompHost is the hostname or distcomp profile.
            %  @return this, a cell-array of TracerDirector instances of size N{sessions} x NUM_VISITS.
            
            ip = inputParser;
            addRequired( ip, 'sessionData',  @(x) isa(x, 'function_handle'));
            addRequired( ip, 'construct',    @(x) isa(x, 'function_handle'));
            addParameter(ip, 'nArgout', 0,   @isnumeric);
            addParameter(ip, 'dirTool',      @(x) isa(x, 'mlsystem.DirTool'));
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            parse(ip, varargin{:});
            
            import mlpet.*;
            those = {};
            for d = 1:length(ip.Results.dirTool.fqdns)
                for v = 1:TracerDirector.NUM_VISITS
                    try
                        sessd = ip.Results.sessionData( ...
                            'studyData',   this.studyData, ...
                            'sessionPath', ip.Results.dirTool.fqdns{d}, ...
                            'vnumber',     v, ...
                            'tracer',      this.sessionData.tracer);
                        this.sessionData = sessd;
                        those{d,v} = TracerDirector.pullFromRemote( ...
                            CHPC4TracerDirector(this, 'distcompHost', ip.Results.distcompHost, 'sessionData', sessd));  %#ok<AGROW>
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end 

