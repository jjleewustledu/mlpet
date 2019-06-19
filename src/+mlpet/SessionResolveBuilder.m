classdef SessionResolveBuilder < mlpet.StudyResolveBuilder
	%% SESSIONRESOLVEBUILDER operates on scans contained in $SUBJECTS_DIR/sub-S000000/ses-E000000

	%  $Revision$
 	%  was created 07-May-2019 01:16:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
   
	methods
        function this = alignCommonModal(this, varargin)
            %  @param required tracer is char.
            %  @return resolution of all scans with specified tracer in the session.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            parse(ip, varargin{:});
            
            prefixes = this.stageSessionScans(ip.Results.tracer, '_avgt');
            if ~isempty(prefixes)
                this = this.resolve(prefixes, varargin{2:end});
            end
            this.tracer = ip.Results.tracer;
        end        
        
        function prefixes = stageSessionScans(this, varargin)
            %% Creates links to tracer images distributed on the filesystem so that resolve operations may be done in the pwd.
            %  e.g.:  HO_DT(yyyymmddHHMMSS).000000-Converted-AC/ho_avgt.4dfp.hdr -> hodt(yyyymmddHHMMSS)_avgt.4dfp.hdr
            %  @param required tracer is char.
            %  @param optional suffix is char, e.g., _avgt.
            %  @return prefixes = cell(1, N(available images)) as unique fileprefixes in the pwd.
            %  TODO:  stageSessionScans -> stageImages
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            addOptional(ip, 'suffix', '', @ischar);
            parse(ip, varargin{:});         
            
            try
                files = this.collectionRB_.lns_with_DateTime( ...
                    sprintf('%s_DT*.000000-Converted-AC/%s%s.4dfp.*', ...
                    upper(ip.Results.tracer), lower(ip.Results.tracer), ip.Results.suffix));
                prefixes = this.collectionRB_.uniqueFileprefixes(files);
            catch ME
                handwarning(ME)
            end
        end    
                
 		function this = SessionResolveBuilder(varargin)
 			%% SESSIONRESOLVEBUILDER
 			%  @param sessionData is an mlpipeline.ISessionData.
            
            this = this@mlpet.StudyResolveBuilder(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

