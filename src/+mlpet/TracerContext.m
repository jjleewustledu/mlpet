classdef TracerContext 
	%% TRACERCONTEXT resembles a decorator for mlfourd.ImagingContext2.

	%  $Revision$
 	%  was created 15-Jan-2020 18:13:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	 	
    properties (Constant)
        SUPPORTED_TRACERS = {'FDG' 'HO' 'OO' 'OC'}
    end
    
	properties (Dependent)
        filepath
        filename
        fileprefix
        filesuffix
        fqfilename
        fqfileprefix
        imagingContext
        sessionData
 		tracer
 	end

	methods 
        
        %% GET/SET
        
        function g = get.filepath(this)
            g = this.imagingContext_.filepath;
        end
        function this = set.filepath(this, s)
            this.imagingContext_.filepath = s;
        end
        function g = get.filename(this)
            g = this.imagingContext_.filename;
        end
        function this = set.filename(this, s)
            this.imagingContext_.filename = s;
        end
        function g = get.fileprefix(this)
            g = this.imagingContext_.fileprefix;
        end
        function this = set.fileprefix(this, s)
            this.imagingContext_.fileprefix = s;
        end
        function g = get.filesuffix(this)
            g = this.imagingContext_.filesuffix;
        end
        function g = get.fqfilename(this)
            g = fullfile(this.filepath, this.filename);
        end
        function this = set.fqfilename(this, s)
            this.imagingContext_.fqfilename = s;
        end
        function g = get.fqfileprefix(this)
            g = fullfile(this.filepath, this.fileprefix);
        end
        function this = set.fqfileprefix(this, s)
            this.imagingContext_.fqfileprefix = s;
        end
        function g = get.imagingContext(this)
            g = copy(this.imagingContext_);
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.tracer(this)
            g = this.sessionData_.tracer;
        end
        
        %% from imagingContext_
        
        function obj = fourdfp(this)
            obj = this.imagingContext_.fourdfp;
        end
        function       fsleyes(this)
            this.imagingContext_.fsleyes;
        end
        function obj = nifti(this)
            obj = this.imagingContext_.nifti;
        end
        
        function this = blurred(this, b)
            this.imagingContext_ = this.imagingContext_.blurred(b);
        end
        function this = minus(this, b)
            if isa(b, 'mlpet.TracerContext')
                this.imagingContext_ = this.imagingContext_.minus(b.imagingContext_);
                return
            end
            this.imagingContext_ = this.imagingContext_.minus(b);
        end
        function this = plus(this, b)
            if isa(b, 'mlpet.TracerContext')
                this.imagingContext_ = this.imagingContext_.plus(b.imagingContext_);
                return
            end
            this.imagingContext_ = this.imagingContext_.plus(b);
        end
        function this = rdivide(this, b)
            if isa(b, 'mlpet.TracerContext')
                this.imagingContext_ = this.imagingContext_.rdivide(b.imagingContext_);
                return
            end
            this.imagingContext_ = this.imagingContext_.rdivide(b);
        end
        function this = scrubNanInf(this)
            this.imagingContext_ = this.imagingContext_.scrubNanInf();
        end
        function this = scrubNegative(this)
            fdfp = this.imagingContext_.fourdfp;
            fdfp.img(fdfp.img < 0) = 0;
            this.imagingContext_ = mlfourd.ImagingContext2(fdfp);
        end
        function this = times(this, b)
            if isa(b, 'mlpet.TracerContext')
                this.imagingContext_ = this.imagingContext_.times(b.imagingContext_);
                return
            end
            this.imagingContext_ = this.imagingContext_.times(b);
        end        
        
        function        save(this)
            this.imagingContext_.save
        end
        function this = saveas(this, fn)
            this.imagingContext_ = this.imagingContext_.saveas(fn);
        end
        function this = timeAveraged(this, varargin)
            this.imagingContext_ = this.imagingContext_.timeAveraged(varargin{:});
        end
        function this = volumeAveraged(this, varargin)
            this.imagingContext_ = this.imagingContext_.volumeAveraged(varargin{:});
        end
        
        %% from sessionData_
        
        function str = datestr(this)
            str = datestr(this.datetime, 'yyyymmddHHMMSS');
        end
        function dt = datetime(this, varargin)
            dt = this.sessionData_.datetime(varargin{:});
        end
        
        %%
        
        function m = maskedMean(this, mask)
            %% @param must be interpretable by mlfourd.ImagingContext2
            
            this.imagingContext_ = this.imagingContext_.masked(mask);
            m = this.imagingContext_.dipsum / mask.dipsum;
        end
		  
 		function this = TracerContext(varargin)
 			%% TRACERCONTEXT
 			%  @param filename must be interpreted by mlfourd.ImagingContext2.
            %  @param imagingContext must be an mlfourd.ImagingContext2.
            %  @param sessionData must be an mlpipeline.ISessionData.

            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'imagingContext', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'filename', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            
            this.sessionData_ = ipr.sessionData;
            this.imagingContext_ = ipr.imagingContext;
            if ~isempty(ipr.filename)
                if ~isempty(this.imagingContext_)
                    this.imagingContext_.filename = ipr.filename;
                else
                    this.imagingContext_ = mlfourd.ImagingContext2(ipr.filename);
                end                
            end
            this = this.refreshSessionData();
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        imagingContext_
        sessionData_
    end
    
    methods (Access = protected)
        function this = refreshSessionData(this)
            %% refreshes internal sessionData with supported tracer abbrev. and existing scan folder name
            
            ss = strsplit(this.fileprefix, 'dt');
            if lstrfind(this.SUPPORTED_TRACERS, upper(ss{1}))
                this.sessionData_.tracer = upper(ss{1});
            end
            re = regexp(this.fileprefix, '\S+(?<dt>\d{14})\S*', 'names');
            fld = sprintf('%s_DT%s.000000-Converted-%s', upper(this.tracer), re.dt, this.sessionData_.attenuationTag);
            if isfolder(fullfile(this.sessionData_.sessionPath, fld, ''))
                this.sessionData_ = this.sessionData_.setScanFolder(fld);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

