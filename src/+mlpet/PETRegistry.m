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
        ORIENTATION_LIST = { 'radial' 'tangential' 'in-plane' 'axial' };
    end

	properties (Dependent)
    end
    
    methods % GET
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
            %  Radial resolution (mm)     4.82   5.65   5.24
            %  Tangential resolution (mm) 4.39   4.64   4.52
            %  In-plane resolution* (mm)  6.52   7.31   6.92
            %  Axial resolution (mm)      5.10   5.33   5.22
            %
            %  Orientation Sigma
            %  Radial resolution (mm)     2.0469 2.3993 2.2252
            %  Tangential resolution (mm) 1.8643 1.9704 1.9195
            %  In-plane resolution* (mm)  2.7688 3.1043 2.9387
            %  Axial resolution (mm)      2.1658 2.2634 2.2167
            %
            %  *geom. mean
        
            p = inputParser;
            addOptional(p, 'scanner',        'ECAT EXACT HR+', @(s) lstrfind(lower(s), this.SCANNER_LIST));
            addOptional(p, 'radialPosition',  7,               @isnumeric);
            addOptional(p, 'dispersion',     'fwhh',           @(s) lstrfind(lower(s), this.DISPERSION_LIST));
            addOptional(p, 'orientation',    'in-plane',       @(s) lstrfind(lower(s), this.ORIENTATION_LIST));
            addOptional(p, 'geometricMean',   false,           @islogical);
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
                    r2  = norm(tanFit(r), radialFit(r));
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
            if (p.Results.geometricMean)
                ps = norm(ps); % 2-norm, Euclidean mean
            end
            
            %% inner methods
            
            function y = axialFit(x)
                y = -0.0008889*x^2 + 0.03533*x + 5.066;
            end
            function y = radialFit(x)
                y = -0.002556*x^2 + 0.1203*x + 4.702;
            end
            function y = tanFit(x)
                y = -0.0009444*x^2 + 0.03817*x + 4.353;
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

