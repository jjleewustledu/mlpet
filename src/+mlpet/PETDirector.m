classdef PETDirector < mlfsl.FslDirector
	%% PETDIRECTOR is the client's director that specifies algorithms for building PET imaging analyses; 
    %  takes part in builder design patterns with PETBuilder and others.
	
	%  Version $Revision: 2610 $ was created $Date: 2013-09-07 19:15:00 -0500 (Sat, 07 Sep 2013) $ by $Author: jjlee $,  
 	%  last modified $LastChangedDate: 2013-09-07 19:15:00 -0500 (Sat, 07 Sep 2013) $ and checked into svn repository $URL: file:///Users/jjlee/Library/SVNRepository_2012sep1/mpackages/mlfsl/src/+mlfsl/trunk/PETDirector.m $ 
 	%  Developed on Matlab 7.13.0.564 (R2011b) 
 	%  $Id: PETDirector.m 2610 2013-09-08 00:15:00Z jjlee $ 
 	%  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad) 
    
    properties (Dependent)
        mrReference
        petReference
        standardAtlas
        standardReference
        tr
        h15oMeanvol
        o15oMeanvol
        c15o
    end
    
    methods %% set/get
        function this = set.petReference(this, ref)
            this.builder_.petReference = ref;
        end
        function ref  = get.petReference(this)
            ref = this.builder_.petReference;
        end
        function this = set.mrReference(this, ref)
            this.builder_.mrReference = ref;
        end
        function ref  = get.mrReference(this)
            ref = this.builder_.mrReference;
        end
        function this = set.standardReference(this, ref)
            this.builder_.standardReference = ref;
        end
        function ref  = get.standardReference(this)
            ref = this.builder_.standardReference;
        end
        function this = set.standardAtlas(this, ref)
            this.builder_.standardAtlas = ref;
        end
        function ref  = get.standardAtlas(this)
            ref = this.builder_.standardAtlas;
        end
        function fp   = get.tr(this)
            fp = this.imagingChoosers_.choose_tr;
        end        
        function fp   = get.h15oMeanvol(this)
            fp = this.imagingChoosers_.choose_h15oMeanvol;
        end
        function fp   = get.o15oMeanvol(this)
            fp = this.imagingChoosers_.choose_o15oMeanvol;
        end
        function fp   = get.c15o(this)
            fp = this.imagingChoosers_.choose_c15o;
        end
    end
    
    methods (Static)
        function this = createFromSessionPath(pth)
            import mlfsl.* mlpet.*;
            this = PETDirector.createFromBuilder( ...
                   mlpet.PETBuilder.createFromSessionPath(pth));
        end
        function this = createFromModalityPath(pth)
            import mlfsl.* mlpet.*;
            this = PETDirector.createFromBuilder( ...
                   mlpet.PETBuilder.createFromModalityPath(pth));
        end
        function this = createFromBuilder(bldr)
            assert(isa(bldr, 'mlpet.PETBuilder'));
            cd(bldr.sessionPath);
            this = mlpet.PETDirector(bldr);
        end
    end
    
    methods
        function this        = convertECAT(this)
            assert(isa(this.builder_, 'mlpet.PETBuilder'));
            this.builder_ = this.builder_.convertECAT;
        end
        function [this,prod] = coregister(this, strat, opts)
            p = inputParser;
            addRequired(p, 'strat', @(x) isa(x, 'mlfsl.FlirtStrategy'));
            addRequired(p, 'opts',  @(x) isa(x, 'mlfsl.FlirtOptions'));
            parse(p, strat, opts);
            
            [this.builder_, omat] = this.builder_.coregister(p.Results.pet, p.Results.ref);
            [this.builder_, prod] = this.builder_.applyTransform( ...
                omat, p.Results.pet, p.Results.ref, ...
                this.builder_.imageObject(p.Results.pet, omat));
        end
        function this        = coregisterPetOnT1(this, ref)
            if (~exist('ref','var'))
                ref = this.mrReference;
            end
            try           
                cd(this.fslPath);     
                this = this.coregister(this.tr, ref);
                this = this.coregister(this.h15oMeanvol, ref);
                this = this.coregister(this.o15oMeanvol, ref);
                this = this.coregister(this.c15o, ref);
            catch ME
                warning(ME.message);
            end
        end
        function this        = coregisterPetOnT2(this, ref)
            if (~exist('ref','var'))
                ref = fullfile(this.fslPath, 't2_default');
            end
            try          
                cd(this.fslPath);      
                this = this.coregister(this.tr, ref);
                this = this.coregister(this.h15oMeanvol, ref);
                this = this.coregister(this.o15oMeanvol, ref);
                this = this.coregister(this.c15o, ref);
            catch ME
                warning(ME.message);
            end
        end
        function [this,prod] = coregisterPetOnPet(this, strat, opts)
            import mlfsl.*;
            if (~exist('strat','var'))
                strat = FlirtContext(this.builder_, 'gauss'); end
            if (~exist('opts','var'))
                opts = mlfsl.FlirtOptions; end
            
            cd(this.fslPath);
               opts.in  = this.tr; 
               opts.ref = this.mrReference;
            [this,prod] = this.coregister(strat, opts);
               opts.in  = this.h15oMeanvol; 
               opts.ref = fileprefix(prod);
            [this,prod] = this.coregister(strat, opts);
               opts.in  = this.o15oMeanvol;
               opts.ref = fileprefix(prod);
             this       = this.coregister(strat, opts);
               opts.in  = this.c15o;
               opts.ref = fileprefix(prod);
            [this,prod] = this.coregister(strat, opts);
        end
        function [this,xfms] = coregisterSequence(this, ial)
            assert(isa(ial, 'mlfourd.ImagingArrayList'));
            error('mlpet:notImplemented', 'PETDirector.coregisterSequence is a method stub');
        end
    end
    
    %% PROTECTED
    
    methods (Access = 'protected')
 		function this = PETDirector(bldr)
            assert(isa(bldr, 'mlpet.PETBuilder'));
			this = this@mlfsl.FslDirector(bldr);
        end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

