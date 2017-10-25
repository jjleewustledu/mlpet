classdef PETRegistry < mlpatterns.Singleton
	%% PETREGISTRY  

	%  $Revision$
 	%  was created 16-Oct-2015 10:49:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
	properties (Constant)
        SCANNER_LIST     = { 'ecat exact hr+' 'siemens biograph mmr' };
        DISPERSION_LIST  = { 'fwhh' 'sigma'};
        ORIENTATION_LIST = { 'radial' 'tangential' 'in-plane' 'axial' '3D' };
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
                this = mlpet.PETRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 
    
    methods
        function ps   = petPointSpread(this, varargin)
            %% PETPOINTSPREAD returns a 3-vector in mm; fwhh or sigma
            %  ps = mlpet.PETBuilder.petPointSpread([attribute, value..., attribute, value])
            %  ^ double                              ^ scanner, radial position, dispersion, orientation
            %
            %  FWHH, (geom.) means of tan. & radial resolution of ECAT EXACT HR+ 2D mode
            %  N. Karakatsanis, et al., Nuclear Instr. & Methods in Physics Research A, 569 (2006) 368--372
            %
            %  Table 1. Spatial resolution for two different radial positions (1 and 10 cm from the center of FOV), 
            %  calculated in accordance with the NEMA NU2-2001 protocol
            %
            %  Experimental results 
            %  Radial position (cm)       1     10     ~5
            %
            %  Orientation FWHH
            %  Radial resolution (mm)     4.82   5.65   5.19
            %  Tangential resolution (mm) 4.39   4.64   4.50
            %  In-plane resolution* (mm)  6.52   7.31   6.87
            %  Axial resolution (mm)      5.10   5.33   5.20
            %
            %  Orientation Sigma
            %  Radial resolution (mm)     2.0469 2.3993 2.2035
            %  Tangential resolution (mm) 1.8643 1.9704 1.9114
            %  In-plane resolution* (mm)  2.7688 3.1043 2.9180
            %  Axial resolution (mm)      2.1658 2.2634 2.2092
            %
            %  *geom. mean
        
            p = inputParser;
            addOptional(p, 'scanner',        'ECAT EXACT HR+', @(s) lstrfind(lower(s), this.SCANNER_LIST));
            addOptional(p, 'radialPosition',  10,              @isnumeric);
            addOptional(p, 'dispersion',     'fwhh',           @(s) lstrfind(lower(s), this.DISPERSION_LIST));
            addOptional(p, 'orientation',    'in-plane',       @(s) lstrfind(lower(s), this.ORIENTATION_LIST));
            addOptional(p, 'geometricMean',   false,           @islogical);
            addOptional(p, 'mean',            false,           @islogical);
            parse(p, varargin{:});
            r = abs(p.Results.radialPosition);
            switch (lower(p.Results.orientation))
                case 'axial'
                    ps = axialFit(r);
                case {'tangential' 'tan'}
                    ps = tanFit(r);
                case 'radial'
                    ps = radialFit(r);
                case 'in-plane'
                    r2  = inPlaneFit(r);
                    ps = [r2 r2 axialFit(r)];
                case '3D'
                    r2  = norm(tanFit(r), radialFit(r));
                    ps = [r2 r2 r2];
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                          'PETRegistry.petPointSpread.orientation->%s', p.Results.orientation);
            end
            if (strcmp(p.Results.dispersion, 'sigma'))
                ps = fwhh2sigma(ps);
            end
            if (p.Results.mean)
                ps = mean(ps)*ones(1,length(ps)); 
            end
            if (p.Results.geometricMean)
                ps = norm(ps); % 2-norm, Euclidean mean
            end
            
            %% inner methods
            
            function y = radialFit(x)
                r1  = 4.82;
                r10 = 5.65;
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
            function y = tanFit(x)
                r1  = 4.39;
                r10 = 4.64;
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
            function y = inPlaneFit(x)
                r1  = norm([4.82 4.39]);
                r10 = norm([5.65 4.64]);
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
            function y = axialFit(x)
                r1  = 5.10;
                r10 = 5.33;
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
        end     
    end
    
	methods (Access = 'private') 		  
 		function this = PETRegistry(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

