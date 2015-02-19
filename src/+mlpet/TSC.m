classdef TSC < mlpet.AbstractScannerData & mlpet.IDecayCorrection
	%% TSC objectifies Mintun-Markham *.tsc files for use with glucose metabolism calculations.   
    %  Tsc files record scanner-array events, correct for positron half-life and adjust scanner-array events to yield well-counter units.
	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    properties (Constant)
        EXTENSION = '.tsc'
        TIMES_UNITS = 'sec'
        COUNTS_UNITS = 'scanner events'
    end
    
	properties
        STUDY_CODES = {'g' 'cg' 'gluc'};
        isotope = '11C'
        petGluc_decayCorrect
        gluTxlsx
        mask
        
        pie = 4.88; % 3D [11C] scans from 2012
    end
    
    properties (Dependent)          
        scanIndex % integer, e.g., last char in 'p1234ho1'
        tracer % char, e.g., 'ho'
        length % integer, number valid frames
        scanDuration % sec  
        dt % sec        
        times
        timeInterpolants
        counts
        countInterpolants
        header
        
        taus
        timeMidpoints
        injectionTime
        useBequerels = false 
        
        nifti
        recFqfilename 
        
        
        
        dtaDuration   
        
        pnumber           
        fslPath  
        scanPath
        petPath
        procPath
        
        maskFqFilename
        glucFqFilename
        recFqFilename      
    end
    
    methods %% GET  
         
        function dd = get.dtaDuration(this)
            assert(~isempty(this.dtaDuration_));
            dd = this.dtaDuration_;
        end
        function t = get.taus(this)
            assert(~isempty(this.taus_));
            t = this.taus_;
        end
        
        function p   = get.pnumber(this)
            p = str2pnum(this.filepath);
        end     
        function pth = get.fslPath(this)
            pth = fullfile(this.filepath, 'fsl', '');
        end 
        function pth = get.scanPath(this)
            pth = fullfile(this.petPath, ['scan' num2str(this.scanIndex)], '');
        end
        function pth = get.petPath(this)
            pth = fullfile(this.filepath, 'PET', '');
        end
        function pth = get.procPath(this)
            pth = fullfile(this.filepath, 'jjl_proc', '');
        end
        
        function f   = get.maskFqFilename(this)
            f = sprintf('brain_finalsurfs_on_%str1.nii.gz', this.pnumber);
            f = fullfile(this.fslPath, f);
        end
        function f   = get.glucFqFilename(this)
            f = sprintf('%sgluc%i.nii.gz', this.pnumber, this.scanIndex);
            f = fullfile(this.scanPath, f);
        end
        function f   = get.recFqFilename(this)
            f = sprintf('%sgluc%i.img.rec', this.pnumber, this.scanIndex);
            f = fullfile(this.scanPath, f);
        end        
    end
    
    methods (Static)
    end

	methods 	
 		function this = TSC(varargin)
            %% TSC
 			%  Usage:  this = TSC(fileprefix[, path]) 
            %          this = TSC('p1234cg1', '/path/to/p1234data')

            this = this@mlpet.AbstractLegacyBetaCurve(varargin{:});
            
            import mlfourd.*;
            this.injectionTime = this.getInjectionTime;
            this.mask      = this.makeMask( ...
                                 NIfTI.load(this.maskFqFilename));
            [this.petGluc_decayCorrect,this.times_,this.taus_] = ...
                             this.decayCorrect( ...
                                 this.maskPet( ...
                                     NIfTI.load(this.glucFqFilename), this.mask));
            this.counts_ = this.plotPet();
            this.dtaDuration_ = this.getDtaDuration;            
            this.gluTxlsx = mlarbelaez.GluTxlsx; 			 
 		end 	 
        function counts = plotPet(this, nii, msk)
            %% PLOTPET plots the time-evolution of the PET data summed over all positions from the tomogram
            %  Usage:  counts = plotPet(PET_NIfTI, mask_NIfTI) 
            %          ^ double vector                       

            assert(isa(nii,    'mlfourd.NIfTI'));
            assert(isa(msk, 'mlfourd.NIfTI'));
            assert(4 == length(nii.size), 'plotPet:  PET NIfTI has no temporal data');
            nii_size = nii.size;
            assert(all(nii_size(1:3) == msk.size));

            counts = zeros(1,nii.size(4));
            for t = 1:nii.size(4)
                counts(t) = sum(sum(sum(nii.img(:,:,:,t) .* msk.img, 1), 2), 3);
            end
            figure;
            plot(counts);
            title([nii.fileprefix ' && ' msk.fileprefix], 'Interpreter', 'none');
            xlabel('time-frame/arbitrary');
            if (~this.useBequerels); ylabel('counts/time-frame');
            else                  ylabel('activity/Bq'); end
        end
        function counts = printTsc(this, fqfn, label, counts, mask)
            %% PRINTTSC ...
            %  Usage:  printTsc(label, counts, mask)
            %                   ^ string
            %                          ^ double, PETcnts
            %                                  ^ boolean NIfTI
            
            fid = fopen(fqfn, 'w');
            
            Nf = this.getNf;
            if (getenv('VERBOSE'))
                fprintf('printTsc:  using pie->%f\n', this.pie); end
            Npixels = mask.dipsum;
            
            % \pi \equiv \frac{wellcnts/cc/sec}{PETcnts/pixel/min}
            % wellcnts/cc = \pi \frac{PETcnts}{pixel} \frac{sec}{min}
            
            counts = this.pie * (counts/Npixels) * 60;
            fprintf(fid, '%s\n', label);
            fprintf(fid, '    %i,    %i\n', Nf, 3);
            for f = 1:Nf
                fprintf(fid, '%12.1f %12.1f %14.2f\n', this.times(f), this.taus(f), counts(f));
            end
            fprintf(fid, 'bool(brain.finalsurfs)\n\n');
            
            fclose(fid);
        end   
        function msk = makeMask(~, nii)
            
            assert(isa(nii, 'mlfourd.NIfTI'));
            assert(3 == length(nii.size), 'mlpet:dataFormatNotSupported', 'Glucnoflow.makeMask.nii.size -> % i', nii.size); %#ok<*MCNPN>
            
            msk = mlfourd.NIfTI(nii);
            msk.fileprefix = [nii.fileprefix '_mask'];
            msk.img = abs(msk.img) > eps;
        end
        function [nii,times,taus] = decayCorrect(this, nii)
            %% DECAYCORRECT ... 
            %  Usage:  [nifti,times,durations] = decayCorrect(nifti);
            %                 ^     ^ double
            %  Uses:  this.isotope, this.injectionTime 
            %         ^ char:  "15O", "11C"
            %                       ^ float, sec

            sz = nii.size;
            NN = 70; % time-resolution used internally for calculations; truncated to nii.size(4)
            switch (this.isotope)
                case '15O'        
                    halfLife           = 122.1;
                    lambda             = log(2) / halfLife; % lambda \equiv 1/tau, tau = 1st-order rate constant 
                    times              = zeros(1,NN);
                    taus               = zeros(1,NN);
                    img                = zeros(sz(1),sz(2),sz(3),NN);
                    img(:,:,:,1:sz(4)) = nii.img;
                    nii.pixdim(4)      = 2;

                    times( 1:31) = this.injectionTime +      2*([2:32] - 2);
                    times(32:NN) = this.injectionTime + 60 + 6*([33:NN+1] - 32);

                    taus( 1:30) = 2;
                    taus(31:NN) = 6;

                    if (this.useBequerels)
                        scaling = [2 6]; %#ok<*UNRCH> % duration of sampling
                    else
                        scaling = [1 1];
                    end

                    for t = 1:30
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(1); end
                    for t = 31:NN
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(2); end

                case '11C'
                    halfLife           = 20.334*60;
                    lambda             = log(2) / halfLife;
                    times              = zeros(1,NN);
                    taus               = zeros(1,NN);
                    img                = zeros(sz(1),sz(2),sz(3),NN);
                    img(:,:,:,1:sz(4)) = nii.img;
                    nii.pixdim(4)      = 30;

                    times( 1:17) = this.injectionTime +         30*([ 2:18] -  2); %#ok<*NBRAK>
                    times(18:25) = this.injectionTime + 480  +  60*([19:26] - 18);
                    times(26:41) = this.injectionTime + 960  + 120*([27:42] - 26);
                    times(42:49) = this.injectionTime + 2880 + 180*([43:50] - 42);
                    times(50:NN) = this.injectionTime + 4320 + 240*([51:NN+1] - 50);

                    taus( 1:16) = 30;
                    taus(17:24) = 60;
                    taus(25:40) = 120;
                    taus(41:48) = 180;
                    taus(49:NN) = 240;        

                    if (this.useBequerels)
                        scaling = [30 60 120 180 240]; % duration of sampling
                    else
                        scaling = [1 1 1 1 1];
                    end

                    for t = 1:16
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(1); end
                    for t = 17:24
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(2); end
                    for t = 25:40
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(3); end
                    for t = 41:48
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(4); end
                    for t = 49:NN
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(5); end

                otherwise
                    error('mfiles:unsupportedPropertyValue', 'decayCorrect did not recognize %s', this.isotope);
            end

            nii.img = img(:,:,:,1:sz(4));
            times   = times(1:sz(4));
            taus    = taus( 1:sz(4));
            nii.fileprefix = [nii.fileprefix '_decayCorrect'];
            if (this.useBequerels)
                nii.fileprefix = [nii.fileprefix '_Bq']; end
        end
        function pet = maskPet(~, pet, msk)
            %% MASKPET accepts PET and mask NIfTIs and masks each time-frame of PET by the mask
            %  Usage:  pet_masked_nifti = maskPet(pet_nifti, mask_nifti) 

            assert(isa(pet, 'mlfourd.NIfTI'));
            assert(isa(msk, 'mlfourd.NIfTI'));
            assert(3 == length(msk.size));

            for t = 1:pet.size(4)
                pet.img(:,:,:,t) = pet.img(:,:,:,t) .* msk.img;
            end
            pet.fileprefix = [pet.fileprefix '_masked'];
        end
    end 

    %% PRIVATE
    
    properties (Access = 'private')
        dtaDuration_
        taus_
    end
    
    methods (Access = 'private')
        function stime = getInjectionTime(this)
            try
                tp = mlio.TextParser.load(this.recFqFilename);
                stime = tp.parseAssignedNumeric('Start time');
            catch ME
                fprintf('Glucnoflow.getInjectionTime failed for %s pet-index %i', this.petPath, this.scanIndex);
                handexcept(ME);
            end
        end 
        function t = getDtaDuration(this)
            dta = mlpet.DTA( ...
                      sprintf('%sg%i', this.pnumber, this.scanIndex), this.procPath);
            t = dta.times(dta.length);
        end
        function nf = getNf(this)
            nf = min([length(this.times) length(this.taus)]);
            for f = 1:nf
                if (this.times(f) + this.taus(f) > this.dtaDuration)
                    nf = f - 1;
                    break; 
                end
            end
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

