classdef Herscovitch1985 < mlpet.AbstractHerscovitch1985
	%% HERSCOVITCH1985  

	%  $Revision$
 	%  was created 28-Jan-2017 12:53:40
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%  It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee,
    %  jjlee@wustl.edu. 
    %
    %  This program is free software: you can redistribute it and/or modify
    %  it under the terms of the GNU General Public License as published by
    %  the Free Software Foundation, version 3.
    %
    %  This program is distributed in the hope that it will be useful,
    %  but WITHOUT ANY WARRANTY; without even the implied warranty of
    %  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %  GNU General Public License for more details.
    % 
    %  You should have received a copy of the GNU General Public License
    %  along with this program.  If not, see 
    %% <https://www.gnu.org/licenses/gpl-3.0.en.html>.
 	
        
    properties
        MAGIC = 0.5711 % KLUDGE
        canonFlows = 10:10:100 % mL/100 g/min
    end
    
    methods (Static)
        function petobs = estimatePetdyn(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));  
            
            import mlpet.*;
            f = AbstractHerscovitch1985.cbfToInvs(cbf);
            lam  = AbstractHerscovitch1985.LAMBDA;
            lamd = LAMBDA_DECAY;  
            aifti = ensureRowVector(aif.timeInterpolants);
            aifwi = ensureRowVector(aif.wellCountInterpolants);
            petobs = zeros(length(f), length(aifti));
            for r = 1:size(petobs,1)
                petobs_ = (1/aif.W)*f(r)*conv(aifwi, exp(-(f(r)/lam + lamd)*aifti));
                petobs(r,:) = petobs_(1:length(aifti));
            end
        end        
        function petobs = estimatePetobs(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));
            
            rho = mlpet.Herscovitch1985.estimatePetdyn(aif, cbf);
            petobs = aif.dt*trapz(rho, 2);
        end
    end
    
	methods
 		function this = Herscovitch1985(varargin)
            this = this@mlpet.AbstractHerscovitch1985(varargin{:});
        end
        
        function this = buildCbvMap(this)
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;            
            sc = sc.blurred(this.videenBlur);
            sc.img = 100*sc.img*this.aif.W/(this.RBC_FACTOR*this.BRAIN_DENSITY*this.aif.wellCountsIntegral);
            sc.fileprefix = this.sessionData.cbv('typ', 'fp');
            %sc = sc.blurred(this.videenBlur);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end       
        function aif  = estimateAifOO(this)
            this = this.ensureAifHOMetab;
            aif = this.aif;
            aif.counts = this.aif.counts - this.aifHOMetab.counts;
        end
        function aif  = estimateAifHOMetab(this)
            aif       = this.aif;
            [~,idxP]  = max(aif.times > this.ooPeakTime);
            dfrac_dt  = this.fracHOMetab/(this.ooFracTime - aif.times(idxP));
            fracVec   = zeros(size(aif.times));
            fracVec(idxP:end) = dfrac_dt*(aif.times(idxP:end) - aif.times(idxP));            
            aif.counts = this.aif.counts.*fracVec;
        end
        function aifi = estimateAifOOIntegral(this)
            aifi = 0.01*this.SMALL_LARGE_HCT_RATIO*this.BRAIN_DENSITY*this.aifOO.countsIntegral;
        end
        
        %% plotting support 
        
        function plotAif(this)
            figure;
            plot(this.aif.times, this.aif.wellCounts);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAif:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            figure;
            plot(this.aifHOMetab.times, this.aifHOMetab.wellCounts);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifHOMetab:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            figure;
            plot(this.aifOO.times, this.aifOO.wellCounts);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifOO:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotScannerWholebrain(this)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            wc = this.scanner.wellCountInterpolants.*this.mask.niftid.img/this.MAGIC/mskvs.double/this.voxelVolume;
            wc = squeeze(sum(sum(sum(wc))));
            plot(this.scanner.timeInterpolants, wc);
            hold on            
            plot(this.aif.timeInterpolants, this.aif.wellCountInterpolants);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotScannerWholebrain:\n%s %s', sd.sessionPath, sd.tracer));
        end 
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

