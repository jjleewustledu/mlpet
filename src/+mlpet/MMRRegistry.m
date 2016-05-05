classdef MMRRegistry < mlpatterns.Singleton
	%% MMRREGISTRY  

	%  $Revision$
 	%  was created 16-Oct-2015 10:49:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
    
    
	properties (Constant)
        DISPERSION_LIST  = { 'fwhh' 'sigma'};
    end
    
    methods
        function g = testStudyData(~, reg)
            assert(ischar(reg));
            g = mlpipeline.StudyDataSingletons.instance(reg);
        end
        function g = testSessionData(this, reg)
            assert(ischar(reg));
            studyData = this.testStudyData(reg);
            iter = studyData.createIteratorForSessionData;
            g = iter.next;
        end
    end
    
    methods (Static)
        function this = instance(qualifier)
            %% INSTANCE uses string qualifiers to implement registry behavior that
            %  requires access to the persistent uniqueInstance
            persistent uniqueInstance
            
            if (exist('qualifier','var') && ischar(qualifier))
                if (strcmp(qualifier, 'initialize'))
                    uniqueInstance = [];
                end
            end
            
            if (isempty(uniqueInstance))
                this = mlpet.MMRRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 
    
    methods
        function ps   = petPointSpread(this, varargin)
            %% PETPOINTSPREAD 
            %  @params optional dispersion may be "fwhh" (default) or "sigma"
            %  @params optional geometricMean is logical (default is false)
            %  @return a scalar or 3-vector in mm
        
            ip = inputParser;
            addOptional(ip, 'dispersion',    'fwhh', @(s) lstrfind(lower(s), this.DISPERSION_LIST));
            addOptional(ip, 'geometricMean',  false, @islogical);
            parse(ip, varargin{:});
            
            ps = [4.3 4.3 4.3];
            if (strcmp(ip.Results.dispersion, 'sigma'))
                ps = fwhh2sigma(ps);
            end
            if (ip.Results.geometricMean)
                ps = norm(ps); % 2-norm, Euclidean mean
            end
        end     
    end
    
	methods (Access = 'private') 		  
 		function this = MMRRegistry(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

