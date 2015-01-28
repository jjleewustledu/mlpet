classdef PETBuilder < mlfsl.FlirtBuilder
	%% PETBUILDER is a concrete builder for all PET tracers
	%  $Revision: 2610 $
 	%  was created $Date: 2013-09-07 19:15:00 -0500 (Sat, 07 Sep 2013) $
 	%  by $Author: jjlee $, 
 	%  last modified $LastChangedDate: 2013-09-07 19:15:00 -0500 (Sat, 07 Sep 2013) $
 	%  and checked into repository $URL: file:///Users/jjlee/Library/SVNRepository_2012sep1/mpackages/mlfsl/src/+mlfsl/trunk/PETBuilder.m $, 
 	%  developed on Matlab 8.0.0.783 (R2012b)
 	%  $Id: PETBuilder.m 2610 2013-09-08 00:15:00Z jjlee $
 	%  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad)

	properties (Constant)
        SCANNER_LIST     = { 'ecat exact hr+' 'siemens mmr' };
        DISPERSION_LIST  = { 'fwhh' 'sigma'};
        ORIENTATION_LIST = { 'radial' 'tangential' 'in-plane' 'axial' };
        POINTSPREAD_MULTIPLIER = 3; %% Derdeyn, Videen, Simmons, et al., Radiology 1999; 212:499-506; uniform Gaussian filtering to 16 mm fwhh
    end
    
    properties (Dependent)
        petReference
    end

    methods (Static) 
        function this = createFromSessionPath(pth)
            assert(lexist(pth, 'dir'));
            this = mlpet.PETBuilder( ...
                   mlfourd.PETConverter.createFromSessionPath(pth));
        end
        function this = createFromModalityPath(pth)
            assert(lexist(pth, 'dir'));
            this = mlpet.PETBuilder( ...
                   mlfourd.PETConverter.createFromModalityPath(pth));
        end
        function this = createFromConverter(cvtr)
            assert(isa(cvtr, 'mlfourd.PETConverter'));d
            this = mlpet.PETBuilder(cvtr);
        end
        function ps   = petPointSpread(varargin)
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
            addOptional(p, 'scanner',         'ECAT EXACT HR+', @(s) lstrfind(lower(s), mlpet.PETBuilder.SCANNER_LIST));
            addOptional(p, 'radial_position',  10,              @isnumeric);
            addOptional(p, 'dispersion',      'fwhh',           @(s) lstrfind(lower(s), mlpet.PETBuilder.DISPERSION_LIST));
            addOptional(p, 'orientation',     'in-plane',       @(s) lstrfind(lower(s), mlpet.PETBuilder.ORIENTATION_LIST));
            parse(p, varargin{:});
            r = abs(p.Results.radial_position);
            switch (lower(p.Results.orientation))
                case 'axial'
                    ps = axialFit(r);
                case {'tangential' 'tan'}
                    ps = tanFit(r);
                case 'radial'
                    ps = radialFit(r);
                otherwise
                    r2  = norm(tanFit(r), radialFit(r));
                    ps = [r2 r2 axialFit(r)];
            end
            if (strcmp(p.Results.dispersion, 'sigma'))
                ps = fwhh2sigma(ps);
            end
            ps = mlpet.PETBuilder.POINTSPREAD_MULTIPLIER*ps;
            
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
        function fp   = maskFqfp(imgcmp)
            fp = fullfileprefix(imgcmp.filepath, ['petmask_' imgcmp.fileprefix]);
        end
        function fp   = maskBinFqfn(imgcmp)
            fp = fullfilename(imgcmp.filepath, ['petmask_bin_' imgcmp.fileprefix]);
        end
        function        createMaskFrom(imgcmp)
            %% createMaskFrom helps generate consistent PET masks
            %  Usage:   PetBuilder.createMaskFrom(imaging_component);
            
            import mlfsl.* mlpet.*;
            imgcmp = ensureCell(imgcmp);
            for n = 1:length(imgcmp)
                assert(isa(imgcmp{n}, 'mlfourd.NIfTIInterface'));
                msk = O15Builder.maskFqfp(imgcmp{n});
                bin = O15Builder.maskBinFqfn(imgcmp{n});
                FlirtBuilder.fslmaths([imgcmp{n}.fqfp ' -s ' num2str(fwhh2sigma(16))  ' ' msk]);
                FlirtBuilder.fslmaths([msk ' -thrp 38.2 -bin ' bin]);
            end
        end
    end

    methods %% set/get
        function this = set.petReference(this, ref)
            fqfn = this.fqfilename(ref);
            assert(lexist(fqfn, 'file'));
            this.petReference_ = fqfn;
        end
        function ref  = get.petReference(this)
            if (isempty(this.petReference_))                
                try               
                    this.petReference_ = this.namingInterface.tr;
                catch ME
                    if (isempty(this.petReference_))
                        error('mlfsl:ParameterCalledBeforeSet', 'PETBuilder.set.petReference');
                    end
                    handexcept(ME);
                end
            end
            ref = this.petReference_;
        end
    end
    
    methods  
        function this       = convertECAT(this)
            assert(isa(this.converter, 'mlfourd.PETConverter'));
            this.converter = this.converter.convertModalityPath(this.modalityPath);
        end   
        function [this,xfm] = coregister(this, im, ref) 
            fs = mlfsl.FlirtContext(this, this.preprocess);
            [fs,xfm] = fs.coregister(im, ref);
            this.lastProduct = fs.lastProduct;
        end
 		function this       = PETBuilder(varargin) 
 			%% PETBUILDER 
 			%  Usage:  prefer factory methods 

 			this = this@mlfsl.FlirtBuilder(varargin{:});
            this.preprocess_ = 'gauss';
 		end %  ctor 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        petReference_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

