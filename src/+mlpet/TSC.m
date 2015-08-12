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
        
        becquerelInterpolants
        maskFilename
    end
    
    methods %% GET 
        function p   = get.pnumberPath(this)
            names = regexp(this.filepath, '(?<pnumberPath>\S+/p\d{4,8}\w+)/\S+', 'names');
            if (isempty(names))
                names = regexp(this.filepath, '(?<pnumberPath>\S+/\S+p\d{4,8}\w+)/\S+', 'names');
            end
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
        function bi  = get.becquerelInterpolants(this)
            bi = pchip(this.times, this.counts ./ this.taus, this.timeInterpolants);
        end
        function f   = get.maskFilename(this)
            f = sprintf('aparc_a2009s+aseg_mask_on_%sgluc%i_mcf.nii.gz', this.pnumber, this.scanIndex);
        end
    end
    
    methods (Static)
        function this = import(tscLoc)    
            %% IMPORT
 			%  Usage:  this = TSC.import(tsc_file_location) 
            %          this = TSC.import('/path/to/p1234data/jjl_proc/p1234wb1.tsc')
            %          this = TSC.import('/path/to/p1234data/jjl_proc/p1234wb1')
            %          this = TSC.import('p1234wb1')     
            
            import mlpet.* mlfourd.*;
            
            this = mlpet.TSC(tscLoc);
            this = this.readtsc;
        end
        function this = loadGluT(pnumPth, scanIdx)
            %% LOADGLUT
 			%  Usage:  this = TSC.loadGluT(pnumber_path, scan_index) 
            %          this = TSC.loadGluT('/path/to/p1234data', 1)
            
            assert(lexist(pnumPth, 'dir'));
            pnum = str2pnum(pnumPth);
            if (isnumeric(scanIdx)); scanIdx = num2str(scanIdx); end
            
            ecatLoc = fullfile(pnumPth, 'PET', ['scan' scanIdx], [pnum 'gluc' scanIdx '_mcf_revf1to5.nii.gz']);
            tscLoc  = fullfile(pnumPth, 'jjl_proc', [pnum 'wb' scanIdx '.tsc']);
            dtaLoc  = fullfile(pnumPth, 'jjl_proc', [pnum 'g'  scanIdx '.dta']);
            this = mlpet.TSC.load(tscLoc, ecatLoc, dtaLoc);            
        end
        function this = load(tscLoc, ecatLoc, dtaLoc)
            %% LOAD
 			%  Usage:  this = TSC.load(tsc_file_location, ecat_file_location,  dta_file_location) 
            %          this = TSC.load('/p1234data/jjl_proc/p1234wb1.tsc', '/p1234data/PET/scan1/p1234gluc1.nii.gz', '/p1234data/jjl_proc/p1234g1.dta')
            %          this = TSC.load('/p1234data/jjl_proc/p1234wb1', '/p1234data/PET/scan1/p1234gluc1', '/p1234data/jjl_proc/p1234g1')
            %          this = TSC.load('p1234wb1', '../PET/scan1/p1234gluc1', 'p1234g1') 
            
            import mlpet.* mlfourd.*;
            
            this = TSC(tscLoc);
            this.mask_ = this.makeMask;
            this.dta_ = DTA(dtaLoc);
            this.decayCorrectedEcat_ = this.maskEcat( ...
                                       DecayCorrectedEcat.load(ecatLoc), this.mask_);
            
            this.times_  = this.decayCorrectedEcat_.times;  
            this.taus_   = this.decayCorrectedEcat_.taus; 
            this.counts_ = this.squeezeVoxels(this.decayCorrectedEcat_, this.mask_);  
            this.header_ = this.decayCorrectedEcat_.header;                 
            
            if (~lexist(this.fqfilename) || ~this.noclobber)
                this.save;
            end
        end
    end

	methods 	
 		function this = TSC(tscLoc)
            %% TSC
 			%  Usage:  this = TSC(tsc_file_location, ecat_file_location,  dta_file_location) 
            %          this = TSC('/p1234data/jjl_proc/p1234wb1.tsc', '/p1234data/PET/scan1/p1234gluc1.nii.gz', '/p1234data/jjl_proc/p1234g1.dta', 4.88)
            %          this = TSC('/p1234data/jjl_proc/p1234wb1', '/p1234data/PET/scan1/p1234gluc1', '/p1234data/jjl_proc/p1234g1', 4.88)
            %          this = TSC('p1234wb1', '../PET/scan1/p1234gluc1', 'p1234g1', 4.88)   
 			%  Usage:  this = TSC(tsc_file_location) 
            %          this = TSC('/path/to/p1234data/jjl_proc/p1234wb1.tsc')
            %          this = TSC('/path/to/p1234data/jjl_proc/p1234wb1')
            %          this = TSC('p1234wb1')   
            %
            % N.B.:  \pi \equiv \frac{wellcnts/cc/sec}{PETcnts/pixel/min}
            %        wellcnts/cc = \pi \frac{PETcnts}{pixel} \frac{sec}{min}

            this = this@mlpet.AbstractWellData(tscLoc);            
        end
        function msk  = makeMask(this)
            msk = mlfourd.MaskingNIfTId.load(this.maskFqfilename);
            if (~lstrfind(msk.fileprefix, 'mask') && ...
                ~lstrfind(msk.fileprefix, 'msk'))
                msk.fileprefix = [msk.fileprefix '_mask'];
            end
        end
        function dcecat = maskEcat(~, dcecat, msk)
            %% MASKPET accepts PET and mask NIfTIs and masks each time-frame of PET by the mask
            %  Usage:  pet_masked_nifti = maskPet(pet_nifti, mask_nifti) 

            assert(isa(dcecat, 'mlpet.EcatExactHRPlus'));
            assert(isa(msk, 'mlfourd.INIfTId'));
            assert(3 == length(msk.size), 'mlpet:unsupportedDataSize', 'TSC.makeMask.mask.size -> % i', msk.size); %#ok<*MCNPN>

            dcecat = dcecat.masked(msk);
        end        
        function cnts = squeezeVoxels(this, ecat, msk)
            %% SQUEEZEVOXELS integrates over space with masking, then divides amplitudes by the number of pixels;
            %  cf. man pie
            
            assert(isa(ecat, 'mlpet.EcatExactHRPlus'));
            Nt = ecat.size(4);
            cnts = zeros(1, Nt);
            dcecat = this.decayCorrectedEcat_;
            for t = 1:Nt
                cnts(t) = sum(sum(sum(dcecat.wellCounts(:,:,:,t), 1), 2), 3) * (60/dcecat.taus(t)); 
            end
            cnts = cnts/mlfourd.MaskingNIfTId.sumall(msk);
        end
        function        plot(this)
            figure;
            plot(this.times, this.counts);
            title([this.decayCorrectedEcat_.fileprefix ' && ' this.mask_.fileprefix], 'Interpreter', 'none');
            xlabel('acquisition-time/sec');
            ylabel('activity/Bq');
            if (~this.useBequerels)
                ylabel('counts/acquisition-frame'); end
        end
        function this = save(this)
            fid = fopen(this.fqfilename, 'w');            
            Nf = this.getNf;
            fprintf(fid, '%s,  %s, %s, pie = %f\n', ...
                    this.dta_.filename, this.mask_.filename, this.decayCorrectedEcat_.filename, this.decayCorrectedEcat_.pie);
            fprintf(fid, '    %i,    %i\n', Nf, 3);
            for f = 1:Nf
                fprintf(fid, '%12.1f %12.1f %14.2f\n', this.times(f), this.taus(f), this.counts(f));
            end
            fprintf(fid, '%s\n\n', this.maskFilename);   
            fclose(fid);
        end
    end 

    %% PROTECTED
    
    properties (Access = 'protected')
        mask_
        dta_
        decayCorrectedEcat_
    end
    
    methods (Access = 'protected')
        function f   = maskFqfilename(this)
            f = fullfile(this.scanPath, this.maskFilename);
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
        function this = readtsc(this)
            fid = fopen(this.fqfilename);
            this = this.readheader(fid);
            this = this.readdata(fid);
            fclose(fid);            
        end
        function this = readheader(this, fid)
            ts = textscan(fid, '%s', 1, 'Delimiter', '\n');
            ts = ts{1}; 
            this.header_.string = ts{1};
            ts = textscan(fid, '%f, %f', 1, 'Delimiter', '\n');
            this.header_.rows = ts{1};
            this.header_.cols = ts{2};
        end
        function this = readdata(this, fid)
            ts = textscan(fid, '%f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times_  = ts{1}';
            this.taus_   = ts{2}';
            this.counts_ = ts{3}';
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

