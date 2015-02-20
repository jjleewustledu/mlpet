classdef TSC < mlpet.AbstractWellData
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
    
    properties (Dependent)
        pnumberPath
        pnumber
        fslPath  
        petPath
        scanPath
        procPath  
    end
    
    methods %% GET 
        function p   = get.pnumberPath(this)
            names = regexp(this.filepath, '(?<pnumberPath>\S+/p\d{4,8}\w+)/\S+', 'names');
            p = names.pnumberPath;
        end
        function p   = get.pnumber(this)
            p = str2pnum(this.pnumberPath);
        end   
        function pth = get.fslPath(this)
            pth = fullfile(this.pnumberPath, 'fsl', '');
        end 
        function pth = get.petPath(this)
            pth = fullfile(this.pnumberPath, 'PET', '');
        end
        function pth = get.scanPath(this)
            pth = fullfile(this.petPath, ['scan' num2str(this.scanIndex)], '');
        end
        function pth = get.procPath(this)
            pth = fullfile(this.pnumberPath, 'jjl_proc', '');
        end
         
    end
    
    methods (Static)
        function this = loadGluT(pnumPth, scanIdx)
            assert(lexist(pnumPth, 'dir'));
            pnum = str2pnum(pnumPth);
            if (isnumeric(scanIdx)); scanIdx = num2str(scanIdx); end
            
            ecatLoc = fullfile(pnumPth, 'PET', ['scan' scanIdx], [pnum 'gluc' scanIdx '.nii.gz']);
            tscLoc  = fullfile(pnumPth, 'jjl_proc', [pnum 'wb' scanIdx '.tsc']);
            dtaLoc  = fullfile(pnumPth, 'jjl_proc', [pnum 'g'  scanIdx '.dta']);
            this = mlpet.TSC.load(tscLoc, ecatLoc, dtaLoc, 4.88);            
        end
        function this = load(tscLoc, ecatLoc, dtaLoc, pie)
            this = mlpet.TSC(tscLoc, ecatLoc, dtaLoc, pie);
        end
    end

	methods 	
 		function this = TSC(tscLoc, ecatLoc, dtaLoc, pie)
            %% TSC
 			%  Usage:  this = TSC(tsc_file_location, ecat_file_location,  dta_file_location, pie_factor) 
            %          this = TSC('/p1234data/jjl_proc/p1234wb1.tsc', '/p1234data/PET/scan1/p1234gluc1.nii.gz', '/p1234data/jjl_proc/p1234g1.dta', 4.88)
            %          this = TSC('/p1234data/jjl_proc/p1234wb1', '/p1234data/PET/scan1/p1234gluc1', '/p1234data/jjl_proc/p1234g1', 4.88)
            %          this = TSC('p1234wb1', '../PET/scan1/p1234gluc1', 'p1234g1', 4.88)   
            %
            % N.B.:  \pi \equiv \frac{wellcnts/cc/sec}{PETcnts/pixel/min}
            %        wellcnts/cc = \pi \frac{PETcnts}{pixel} \frac{sec}{min}

            this = this@mlpet.AbstractWellData(tscLoc);
            
            import mlpet.* mlfourd.*;
            this.mask_ = this.makeMask;
            this.dta_ = DTA(dtaLoc);
            this.decayCorrectedEcat_ = this.maskEcat( ...
                                       DecayCorrectedEcat( ...
                                       EcatExactHRPlus(ecatLoc), pie), this.mask_);
            
            this.times_  = this.decayCorrectedEcat_.times;  
            this.taus_   = this.decayCorrectedEcat_.taus; 
            this.counts_ = this.squeezeVoxels(this.decayCorrectedEcat_, this.mask_);  
            this.header_ = this.decayCorrectedEcat_.header;         
                 
            
            if (~lexist(this.fqfilename) || ~this.noclobber)
                this.save;
            end
        end
        function msk  = makeMask(this)
            msk = mlfourd.NIfTI.load(this.maskFqfilename);
            msk.img = abs(msk.img) > eps;
            msk.fileprefix = [msk.fileprefix '_mask'];
        end
        function ecat = maskEcat(~, ecat, msk)
            %% MASKPET accepts PET and mask NIfTIs and masks each time-frame of PET by the mask
            %  Usage:  pet_masked_nifti = maskPet(pet_nifti, mask_nifti) 

            assert(isa(ecat, 'mlpet.EcatExactHRPlus'));
            assert(isa(msk, 'mlfourd.NIfTI'));
            assert(3 == length(msk.size), 'mlpet:unsupportedDataSize', 'TSC.makeMask.mask.size -> % i', msk.size); %#ok<*MCNPN>

            nii = ecat.nifti;
            for t = 1:nii.size(4)
                nii.img(:,:,:,t) = nii.img(:,:,:,t) .* msk.img;
            end
            nii.fileprefix = [nii.fileprefix '_masked'];
            ecat.nifti = nii;
        end        
        function cnts = squeezeVoxels(this, ecat, msk)
            assert(isa(ecat, 'mlpet.EcatExactHRPlus'));
            Nt = ecat.nifti.size(4);
            cnts = zeros(1, Nt);
            for t = 1:Nt
                cnts(t) = sum(sum(sum(this.decayCorrectedEcat_.nifti.img(:,:,:,t), 1), 2), 3); 
            end
            cnts = cnts/msk.dipsum;
        end
        function        plot(this)            
            figure;
            plot(this.times, this.counts);
            title([this.decayCorrectedEcat_.fileprefix ' && ' this.mask_.fileprefix], 'Interpreter', 'none');
            xlabel('acquisition-time/sec');
            if (~this.useBequerels); ylabel('counts/acquisition-frame');
            else                     ylabel('activity/Bq'); end
        end
        function this = save(this)
            fid = fopen(this.fqfilename, 'w');            
            Nf = this.getNf;
            fprintf(fid, '%s,  %s, %s, pie = %f\n', ...
                    this.dta_.filename, this.mask_.filename, this.decayCorrectedEcat_.nifti.filename, this.decayCorrectedEcat_.pie);
            fprintf(fid, '    %i,    %i\n', Nf, 3);
            for f = 1:Nf
                fprintf(fid, '%12.1f %12.1f %14.2f\n', this.times(f), this.taus(f), this.counts(f));
            end
            fprintf(fid, 'bool(brain.finalsurfs)\n\n');            
            fclose(fid);
        end
    end 

    %% PRIVATE
    
    properties (Access = 'private')
        mask_
        dta_
        decayCorrectedEcat_
    end
    
    methods (Access = 'private')
        function f   = maskFqfilename(this)
            f = sprintf('brain_finalsurfs_on_%str1.nii.gz', this.pnumber);
            f = fullfile(this.fslPath, f);
        end  
        function nf = getNf(this)
            nf = length(this.times);
            dd = this.dta_.times(this.dta_.length);
            for f = 1:nf
                if (this.times(f) + this.taus(f) > dd)
                    nf = f - 1;
                    break; 
                end
            end
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

