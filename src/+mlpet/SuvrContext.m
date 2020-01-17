classdef SuvrContext < mlpet.TracerContext
	%% SUVRCONTEXT  

	%  $Revision$
 	%  was created 15-Jan-2020 18:18:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
    
	properties (Dependent) 		
        timeWindowDelaySuvr
        timeWindowDurationSuvr 
    end

	methods 
        
        %% GET        
        
        function g = get.timeWindowDelaySuvr(this)
            switch (this.tracer)
                case 'FDG'
                    g = 40*60;
                case {'OC' 'CO'}
                    g = 2*60;
                case {'OO' 'HO'}
                    g = 0;
                otherwise
                    error('mlpet:unsupportedSwitchcase', 'TracerSuvrBuilder.get.timeWindowDurationSuvr');
            end
        end
        function g = get.timeWindowDurationSuvr(this)
            switch (this.tracer)
                case 'FDG'
                    g = 20*60;
                case {'OC' 'CO' 'OO' 'HO'}
                    g = 60;
                otherwise
                    error('mlpet:unsupportedSwitchcase', 'TracerSuvrBuilder.get.timeWindowDurationSuvr');
            end
        end
        
        %%
        
        function obj = fqfilenameTimeWindowed(this, varargin)
            [~,idx0] = max(this.sessionData_.times >= this.windowt0());
            t0 = this.windowt0() - this.sessionData_.taus(idx0);
            tF = this.windowtF();
            fqfn = sprintf('%s_times%i-%is.4dfp.hdr', this.fqfileprefix, round(t0), round(tF));
            obj = this.sessionData_.fqfilenameObject(fqfn, varargin{:});
        end
        function this = timeAveraged(this, varargin)
            [~,idx0] = max(this.sessionData_.times >= this.windowt0());
            [~,idxF] = max(this.sessionData_.times >= this.windowtF());
            indices0 = idx0:idxF;
            ip = inputParser;
            addParameter(ip, 'indices', indices0, @isnumeric) % e.g., 1:10
            addParameter(ip, 'suffix', 'none', @ischar)
            parse(ip, varargin{:})
            this.imagingContext_ = this.imagingContext_.timeAveraged(ip.Results.indices);
            if strcmp(ip.Results.suffix, 'none')
                ss = strsplit(this.imagingContext_.fileprefix, '_avgt');
                this.imagingContext_.fileprefix = ss{1};
            end
        end
		  
 		function this = SuvrContext(varargin)
 			%% SUVRCONTEXT

 			this = this@mlpet.TracerContext(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function t0 = windowt0(this)
            ses = this.sessionData_;
            [~,idx] = max(ses.times >= this.timeWindowDelaySuvr);
            t0 = ses.times(idx);
        end
        function tF = windowtF(this)
            ses = this.sessionData_;
            [~,idx] = max(ses.times >= this.timeWindowDelaySuvr + this.timeWindowDurationSuvr);
            tF = ses.times(idx);
            if tF < this.windowt0()
                tF = ses.times(end);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

