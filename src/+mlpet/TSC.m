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
        ROW_COL_HEADER = '%f %f'
    end
    
    properties
        regionIndex = 1
    end
    
    properties (Dependent)
        pnumberPath
        pnumber
        fslPath  
        petPath
        scanPath
        procPath  
        
        becquerels
        becquerelInterpolants
        specificActivity
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
        function b   = get.becquerels(this)
            b = this.counts ./ this.taus;
        end
        function bi  = get.becquerelInterpolants(this)
            bi = pchip(this.times, this.counts ./ this.taus, this.timeInterpolants);
        end
        function b   = get.specificActivity(this)
            b = this.counts ./ this.taus;
        end
    end
    
    methods (Static)
        function this = import(varargin)
            %% IMPORT reads existing *.tsc files
 			%  Usage:  this = TSC.import(tsc_file_location) 
            %          this = TSC.import('/path/to/p1234data/jjl_proc/p1234wb1.tsc')
            %          this = TSC.import('/path/to/p1234data/jjl_proc/p1234wb1')
            %          this = TSC.import('p1234wb1')     
            
            ip = inputParser;
            addRequired(ip, 'tscLoc', @ischar);
            addOptional(ip, 'regionIndex', 1, @isnumeric);
            parse(ip, varargin{:});
            
            import mlpet.* mlfourd.*;            
            this = mlpet.TSC(ip.Results.tscLoc);
            this.regionIndex = ip.Results.regionIndex;
            this = this.readtsc;
            this = this.excludeZeroCounts;
        end
        function this = load(tscLoc, ecatLoc, dtaLoc, maskLoc, varargin)
            %% LOAD loads ecat, dta and mask datafiles, then generates and saves a new tsc datafile
 			%  Usage:  this = TSC.load(tsc_file_location, ecat_file_location,  dta_file_location, mask_file_location) 
            %          this = TSC.load('/p1234data/jjl_proc/p1234wb1.tsc', '/p1234data/PET/scan1/p1234gluc1.nii.gz', '/p1234data/jjl_proc/p1234g1.dta')
            %          this = TSC.load('/p1234data/jjl_proc/p1234wb1', '/p1234data/PET/scan1/p1234gluc1', '/p1234data/jjl_proc/p1234g1')
            %          this = TSC.load('p1234wb1', '../PET/scan1/p1234gluc1', 'p1234g1') 
            
            ip = inputParser;
            addRequired(ip,  'tscLoc', @ischar);
            addRequired(ip, 'ecatLoc', @(x) lexist(x, 'file'));
            addRequired(ip,  'dtaLoc', @(x) lexist(x, 'file'));
            addRequired(ip, 'maskLoc', @(x) lexist(x, 'file'));
            addOptional(ip, 'short', false, @islogical);
            parse(ip, tscLoc, ecatLoc, dtaLoc, maskLoc, varargin{:});
            
            import mlpet.* mlfourd.*;            
            this         = TSC(ip.Results.tscLoc);
            this.mask_   = this.makeMask(ip.Results.maskLoc);
            this.dta_    = DTA.load(ip.Results.dtaLoc, ip.Results.short);
            this.decayCorrectedEcat_ ...
                         = this.maskEcat(DecayCorrectedEcat.load(ip.Results.ecatLoc), this.mask_);            
            this.times_  = this.decayCorrectedEcat_.times;
            this.taus_   = this.decayCorrectedEcat_.taus; 
            this.counts_ = this.squeezeVoxels(this.decayCorrectedEcat_, this.mask_);  
            this.header_ = this.decayCorrectedEcat_.header;                 
            
            if (~lexist(this.fqfilename) || ~this.noclobber)
                this.save;
            end
        end
        function this = loadGluTFiles(files)
            %% LOADGLUTFILES is a convenience method for processing GluT studies
            
            assert(lstrfind(class(files), 'mlarbelaez.GluTFiles'));
            this = mlpet.TSC.load( ...
                files.tscFqfilename, files.ecatFqfilename, files.dtaFqfilename, files.maskFqfilename);
        end
        function this = loadNp755Files(files)
            %% LOADNP755FILES is a convenience method for processing np755 studies
            
            assert(isa(files, 'mlderdeyn.Np755Files'));
            this = mlpet.TSC.load( ...
                files.tscFqfilename, files.ecatFqfilename, files.dtaFqfilename, files.maskFqfilename);
        end
        function this = loadSessionData(sessDat)
            assert(isa(sessDat, 'mlpipeline.SessionData'));
            this = mlpet.TSC(sessDat.tsc_fqfn, sessDat.pet_fqfn, sessDat.dta_fqfn, sessDat.mask_fqfn);
        end
        function msk  = makeMask(maskFqfn)
            %% MAKEMASK accepts a f. q. filename for creating a MaskingNIfTId object.
            
            msk = mlfourd.MaskingNIfTId.load(maskFqfn);
        end
        function dcecat = maskEcat(dcecat, msk)
            %% MASKPET accepts PET and mask NIfTIs and masks each time-frame of PET by the mask
            %  Usage:  pet_masked_nifti = maskPet(pet_nifti, mask_nifti) 

            assert(isa(dcecat, 'mlpet.EcatExactHRPlus'));
            assert(isa(msk, 'mlfourd.INIfTI'));
            assert(3 == length(msk.size), 'mlpet:unsupportedDataSize', 'TSC.makeMask.mask.size -> % i', msk.size); %#ok<*MCNPN>

            dcecat = dcecat.masked(msk);
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
            fprintf(fid, '%s\n\n', this.mask_.fqfilename);   
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
        function this = excludeZeroCounts(this)
            nonzero      = this.counts_ ~= 0;
            this.counts_ = this.counts_(nonzero);
            this.taus_   = this.taus_(  nonzero);
            this.times_  = this.times_( nonzero);
        end
        function cnts = squeezeVoxels(this, ecat, msk)
            %% SQUEEZEVOXELS integrates over space with masking, multiplies by 60/tau, tau in sec, 
            %  then divides amplitudes by the number of pixels;
            %  cf. man pie
            
            assert(isa(ecat, 'mlpet.EcatExactHRPlus'));
            Nt = ecat.size(4);
            cnts = zeros(1, Nt);
            dcecat = this.decayCorrectedEcat_;
            for t = 1:Nt
                cnts(t) = sum(sum(sum(dcecat.wellCounts(:,:,:,t), 1), 2), 3) * (60/dcecat.taus(t)); 
            end
            cnts = cnts/dipsum(msk);
        end
        function nf   = getNf(this)
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
            switch (this.header.cols)
                case 3
                    this = this.read3cols(fid);
                case 4
                    this = this.read4cols(fid);
                case 5
                    this = this.read5cols(fid);
                case 6
                    this = this.read6cols(fid);
                otherwise
                    error('mlpet:unsupportedHeaderParam', 'TSC.readtsc.header.cols -> %i', this.header.cols);
            end
            fclose(fid);            
        end
        function this = readheader(this, fid)
            ts = textscan(fid, '%s', 1, 'Delimiter', '\n');
            ts = ts{1}; 
            this.header_.string = ts{1};
            ts = textscan(fid, this.ROW_COL_HEADER, 1, 'Delimiter', '\n');
            this.header_.rows = ts{1};
            this.header_.cols = ts{2};
        end
        function this = read3cols(this, fid)
            ts = textscan(fid, '%f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times_  = ts{1}';
            this.taus_   = ts{2}';
            this.counts_ = ts{3}';
        end
        function this = read4cols(this, fid)
            ts = textscan(fid, '%f %f %f %f', 'Delimiter', ',');
            this.times_  = ts{1}';
            this.taus_   = ts{2}';
            switch (this.regionIndex)
                case 1
                    this.counts_ = ts{3}';
                case 2
                    this.counts_ = ts{4}';
                otherwise
                    error('mlpet:unexpectedParamValue', 'TSC.regionIndex -> %i', this.scanIndex);
            end
        end
        function this = read5cols(this, fid)
            ts = textscan(fid, '%f %f %f %f %f', 'Delimiter', ',');
            this.times_  = ts{1}';
            this.taus_   = ts{2}';
            switch (this.regionIndex)
                case 1
                    this.counts_ = ts{3}';
                case 2
                    this.counts_ = ts{4}';
                case 3
                    this.counts_ = ts{5}';
                otherwise
                    error('mlpet:unexpectedParamValue', 'TSC.regionIndex -> %i', this.scanIndex);
            end
        end
        function this = read6cols(this, fid)
            ts = textscan(fid, '%f %f %f %f %f %f', 'Delimiter', ',');
            this.times_  = ts{1}';
            this.taus_   = ts{2}';
            switch (this.regionIndex)
                case 1
                    this.counts_ = ts{3}';
                case 2
                    this.counts_ = ts{4}';
                case 3
                    this.counts_ = ts{5}';
                case 4
                    this.counts_ = ts{6}';
                otherwise
                    error('mlpet:unexpectedParamValue', 'TSC.regionIndex -> %i', this.scanIndex);
            end
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

