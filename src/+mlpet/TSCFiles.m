classdef TSCFiles  
	%% TSCFILES   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.6.0.232648 (R2015b) 
 	%  $Id$ 
 	 
    properties (Constant)
        ECAT_FILE_SUFFIX = '_mcf_revf1to5.nii.gz'
        DEFAULT_MASK = 'aparc_a2009s+aseg_mask'
    end

	properties (Dependent)
        pnumPath
        dtaFqfilename
        ecatFqfilename
        maskFqfilename
        tscFqfilename
        
        pnum
        scanIndex
        region
    end 

    methods %% GET
        function p = get.pnumPath(this)
            p = this.pnumPath_;
        end
        function f = get.tscFqfilename(this)
            f = fullfile( ...
                this.pnumPath, 'jjl_proc', ...
                sprintf('%swb%i.tsc', this.pnum, this.scanIndex));
        end
        function f = get.ecatFqfilename(this)
            f = fullfile( ...
                this.pnumPath, 'PET', sprintf('scan%i', this.scanIndex), ...
                sprintf('%sgluc%i%s', this.pnum, this.scanIndex, this.ECAT_FILE_SUFFIX));
        end
        function f = get.dtaFqfilename(this)
            f = fullfile( ...
                this.pnumPath, 'jjl_proc', ...
                sprintf('%sg%i.dta', this.pnum, this.scanIndex));
        end
        function f = get.maskFqfilename(this)
            if (isempty(       this.region_) || ...
                lstrfind(lower(this.region_), 'whole') || ...
                lstrfind(lower(this.region_), 'brain') );
                f = sprintf('%s_on_%sgluc%i_mcf.nii.gz', this.DEFAULT_MASK, this.pnum, this.scanIndex);
            else
                f = this.region_;
                if (~lstrfind(this.region_, '.nii.gz'))
                    f = sprintf('%s.nii.gz', f);
                end
            end
            f = fullfile( ...
                this.pnumPath, 'PET', sprintf('scan%i', this.scanIndex), f);
        end
        
        function p = get.pnum(this)
            p = str2pnum(this.pnumPath);
        end
        function s = get.scanIndex(this)
            s = this.scanIndex_;
        end
        function r = get.region(this)
            r = this.region_;
        end
    end
    
	methods 		  
 		function this = TSCFiles(varargin) 
 			%% TSCFILES 
 			%  Usage:  this = TSCFiles() 

            ip = inputParser;
            addParameter(ip, 'pnumPath', pwd, @(x) lexist(x, 'dir') && lstrfind(x, 'p'));
            addParameter(ip, 'scanIndex', 1, @isnumeric);
            addParameter(ip, 'region', '', @ischar);
            parse(ip, varargin{:});
 			 
            this.pnumPath_  = ip.Results.pnumPath;            
            this.scanIndex_ = ip.Results.scanIndex;
            this.region_    = ip.Results.region;
 		end 
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        pnumPath_
        scanIndex_
        region_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end
