classdef TracerReportsBuilder < mlpet.AbstractTracerBuilder
	%% TRACERREPORTSBUILDER  

	%  $Revision$
 	%  was created 04-Oct-2017 19:05:34 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = TracerReportsBuilder(varargin)
 			%% TRACERREPORTSBUILDER
 			%  Usage:  this = TracerReportsBuilder()

            this = this@mlpet.AbstractTracerBuilder(varargin{:});
            
            sd = this.sessionData;
            sd.epoch = [];
            pwd0 = pushd(sd.tracerLocation);
            dtepochs = mlsystem.DirTool('E*');
            for e = 1:length(dtepochs.fqdns)
                sd.epoch = this.epochDir2Numeric(dtepochs.fqdns{e});
                this.reporter_ = T4ResolveReporter( ...
                    'sessionData', sd, ...
                    'imagingPath', sd.TracerLocation, ...
                    'loggingPath', fullfile(sd.tracerLocation, 'Log', ''), ...
                    'imagingFileprefix', sd.tracerResolvedFinal('typ', 'fp'), ...
                    'loggingFileprefix', this.logFileprefix(sd), ...
                    'frameLength', this.frameLength(sd));
            end            
            popd(pwd0);
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        reporter_
    end
    
    methods (Access = protected)
        function n = frameLength(~, sd)
            sz = this.buildVisitor.ifhMatrixSize( ...
                sd.tracerResolvedFinal('typ', '.4dfp.ifh'));
            assert(length(sz) == 4);
            n = sz(4);
        end
        function fp = logFileprefix(~, sd)
            dtlogs = mlsystem.DirTool(fullfile(sd.TracerLocation, 'Log', '*r1_T4ResolveBuilder_resolveAndPaste_D*.log')); % r1 reveals more of the relevant motions
            for l = 1:length(dtlogs)
                datetimes(l) = datetime(dtlogs.itsListing(l).date); %#ok<AGROW>
            end
            [~,idxs] = sort(datetimes);
            fp = dtlogs.fp{idxs(end)};
        end
        function n = epochDir2Numeric(~, d)
            assert(strcmp(d(1), 'E'));
            if (~lstrfind(d, 'to'))
                n = str2double(d(2:end));
                return
            else
                posTo  = strfind(d, 'to');
                n = str2double(d(2:posTo-1)):str2double(d(posTo+2:end));
                return
            end
            error('mlpet:unexpectedParamValue', 'TracerReportsBuilder.epochDir2Numeric.d -> %s', d);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

