classdef ReferenceFdgSumt 
	%% REFERENCEFDGSUMT  

	%  $Revision$
 	%  was created 25-Jul-2018 17:48:48 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        DATAROOT = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlfourd', 'data', '')
        FILEPREFIX = 'fdgv2ConvertedDefault_dcm2niix'
    end
    
    properties (Dependent)
        asStruct
    end
    
	methods (Static)
        function copyfiles(dest, varargin)
            assert(isdir(dest));
            import mlpet.*;
            suf = {'.nii.gz' '.4dfp.hdr'};
            for s = 1:length(suf)
                copyfile(fullfile(ReferenceFdgSumt.DATAROOT, [ReferenceFdgSumt.FILEPREFIX suf{s}]), dest, varargin{:});
            end
        end
        function g = dicomAsNiigz
            import mlpet.*;
            g = fullfile(ReferenceFdgSumt.DATAROOT, [ReferenceFdgSumt.FILEPREFIX '.nii.gz']);
        end
        function g = dicomAsFourdfp
            import mlpet.*;
            g = fullfile(ReferenceFdgSumt.DATAROOT, [ReferenceFdgSumt.FILEPREFIX '.4dfp.hdr']);
        end
 	end 
    
    methods
        
        %% GET
        
        function g = get.asStruct(this)
            g = this.asstruct_;
        end 
        
        %%
        
        function this = ReferenceFdgSumt
            this.asstruct_ = mlniftitools.load_untouch_nii(this.dicomAsNiigz);
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        asstruct_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

