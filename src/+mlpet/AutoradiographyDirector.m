classdef AutoradiographyDirector  
	%% AUTORADIOGRAPHYDIRECTOR   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties (Constant)
        dcvFilename  = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1.dcv'
        ecatFilename = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1.nii.gz'
        pie = 5.5
    end 
    
    methods (Static)
        function pa  = runForData
            %% RUNFORDATA returns a PETAutoradiography object based on mm01-007_p7267 dcv, ecat
            
            import mlpet.*;
            ecat   = DecayCorrectedEcat.load( ...
                         AutoradiographyDirector.ecatFilename, AutoradiographyDirector.pie);
            dcv    = DCV(AutoradiographyDirector.dcvFilename);
            conc_a = pchip(dcv.timeInterpolants, dcv.countInterpolants, ecat.timeInterpolants);
            pa     = PETAutoradiography.runPETAutoradiography( ...
                     conc_a, ecat.timeInterpolants, ecat.countInterpolants);
        end
        function sim = runSimulation
            %% RUNSIMULATION returns an entirely synthetic PETAutoradiography object

            import mlpet.*;
            times  = 0:1:119;
            conc_a = exp(-(times - 30).^2/(2*5^2));
            conc_i = exp(-(times - 30).^2/(2*10^2));
            this = AutoradiographyDirector( ...
                   PETAutoradiography(conc_a, times, conc_i));
            sim  = this.constructSimulation;
        end
    end

	methods 		  
 		function this = AutoradiographyDirector(buildr) 
 			%% AUTORADIOGRAPHYDIRECTOR 
 			%  Usage:  this = AutoradiographyDirector(PETAutoradiography_object) 

            assert(isa(buildr, 'mlpet.PETAutoradiography'));
            this.builder_ = buildr;
        end 
        
        function constructPlots(this)
        end
        function sim = constructSimulation(this)            
            f      = 0.01;
            PS     = 1;
            t      = this.builder_.times;
            conc_a = this.builder_.concentration_a; 
            aMap   = containers.Map; 
            aMap('f')  = struct('fixed', 0, 'min', f/2,  'mean', f,   'max', 2*f);      
            aMap('PS') = struct('fixed', 0, 'min', PS/2, 'mean', PS,  'max', 2*PS); 
            
            sim = this.builder_.simulateMcmc(f, PS, t, conc_a, aMap);
        end
        function getParams(this)
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        builder_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

