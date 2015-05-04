classdef EcatExactHRPlus < mlfourd.NIfTIdecorator & mlpet.IScannerData
	%% ECATEXACTHRPLUS implements mlpet.IScannerData for data from detection array of Ecat Exact HR+ scanners.
    %  Most useful properties will be times, timeInterpolants, counts, countInterpolants.  It is also a NIfTIdecorator.
    %  The corresponding class for well-counter data is mlpet.AbstractWellData.  Also see mlpet.TSC.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  

    properties  
        dt = 1 % sec, for timeInterpolants
        useBecquerels = false % boolean for dividing accumulated counts by sampling durations of each time-frame to obtain 1/sec  
    end
    
    properties (Dependent)
        
        %% IWellData
        
        scanIndex % integer, e.g., last char in 'p1234ho1'
        tracer % char, e.g., 'ho'
        length % integer, number valid frames
        scanDuration % sec   
        times
        counts
        header
        
        %% IScannerData
        
        taus
        timeMidpoints %% cf. man petproc
        injectionTime
        recFqfilename 	
        wellFqfilename
        wellFactor
        pie
        wellCounts
        mask
        nPixels
    end 

    methods %% GET
        
        %% IWellData
        
        function idx  = get.scanIndex(this)
            names = regexp(this.component_.fileprefix, mlpet.PETIO.SCAN_INDEX_EXPR, 'names');
            idx = str2double(names.idx);
        end
        function t    = get.tracer(this)
            names = regexp(this.component_.fileprefix, mlpet.PETIO.TRACER_EXPR, 'names');
            t = names.tracer;
        end
        function l    = get.length(this)
            assert(~isempty(this.times_));
            l = length(this.times);
        end
        function sd   = get.scanDuration(this)
            assert(~isempty(this.times_));
            sd = this.times_(end);
        end
        function t    = get.times(this)
            assert(~isempty(this.times_));
            t = this.times_;
        end
        function this = set.times(this, t)
            assert(isnumeric(t));
            this.times_ = t;
        end
        function c    = get.counts(this)
            assert(~isempty(this.component_.img));
            c = this.component_.img;
        end
        function this = set.counts(this, c)
            assert(isnumeric(c));
            this.component_.img = c;
        end
        function h    = get.header(this)
            assert(~isempty(this.header_));
            h = this.header_;
        end
        function this = set.header(this, h)
            if (isstruct(h))
                this.header_ = h; end            
        end
        
        %% IScannerData
        
        function t   = get.taus(this)
            assert(~isempty(this.taus_));
            t = this.taus_;
        end
        function tmp = get.timeMidpoints(this)
            assert(~isempty(this.timeMidpoints_));
            tmp = this.timeMidpoints_;
        end
        function t   = get.injectionTime(this)
            t = this.header.injectionTime;
        end
        function f   = get.recFqfilename(this)
            f = sprintf('%s.img.rec', this.component_.fqfileprefix);
        end
        function f   = get.wellFqfilename(this)
            f = fullfile(this.component.filepath, sprintf('%s.wel', str2pnum(this.component.fileprefix)));
        end
        function w   = get.wellFactor(this)
            assert(~isempty(this.wellMatrix_), ...
                'DecayCorrection.get.wellFactor:  this.wellMatrix_ was empty');
            w = this.wellMatrix_(5,1); 
        end
        function p   = get.pie(this)
            p = this.pie_;
        end
        function wc  = get.wellCounts(this)
            wc = this.petCounts2wellCounts(this.counts);
        end
        function m   = get.mask(this)
            m = this.mask_;
        end
        function n   = get.nPixels(this)
            if (isempty(this.mask_))
                n = prod(this.component.size(1:3));
            else
                assert(1 == max(max(max(this.mask_.img))));
                assert(0 == min(min(min(this.mask_.img))));
                n = sum(sum(sum(this.mask_.img)));
            end
        end
    end
    
    methods (Static)
        function this = load(pie, varargin)
            this = mlpet.EcatExactHRPlus(pie, mlfourd.NIfTId.load(varargin{:}));
        end
    end
    
	methods
 		function this = EcatExactHRPlus(pie, cmp) 
 			%% ECATEXACTHRPLUS 
 			%  Usage:  this = EcatExactHRPlus(file_location) 
            %          this = EcatExactHRPlus('/path/to/p1234data/p1234ho1.nii.gz')
            %          this = EcatExactHRPlus('/path/to/p1234data/p1234ho1')
            %          this = EcatExactHRPlus('p1234ho1') 
 			
            this = this@mlfourd.NIfTIdecorator(cmp);
            this = this.append_descrip('decorated by EcatExactHRPlus');
            
            assert(lexist(this.recFqfilename));     
            this = this.readRec;
            this = this.readWellMatrix; 
            this = this.setTimeMidpoints;
            
            assert(isnumeric(pie) && isscalar(pie));
            this.pie_ = pie;
 		end 
        function this = save(this)
            this.component_.fqfileprefix = sprintf('%s_%s', this.component_.fqfileprefix, datestr(now, 30));
            this.component_.save;
        end
        function this = saveas(this, fqfn)
            this.component_.fqfilename = fqfn;
            this.save;
        end
        function i    = guessIsotope(this)
            if (lstrfind(this.tracer, {'ho' 'oo' 'oc' 'co'}))
                i = '15O';
                return
            end
            if (lstrfind(this.tracer, 'g'))
                i = '11C';
                return
            end            
            error('mlpet:indeterminatePropertyValue', ...
                'AbstractScannerData.guessIsotope could not recognize the isotope of %s', this.fileprefix);
        end
        function t    = timeInterpolants(this, varargin)
            assert(~isempty(this.times_));
            t = this.times_(1):this.dt:this.times_(end);
            
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function c    = countInterpolants(this, varargin)
            c  = pchip(this.times, this.counts, this.timeInterpolants);
            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function wc   = wellCountInterpolants(this, varargin)
            wc = pchip(this.times, this.wellCounts, this.timeInterpolants);
            
            if (~isempty(varargin))
                wc = wc(varargin{:}); end
        end
        
        function this = volumeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component_); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.volumeSummed;
            this.component_ = dyn.component_;
        end
        function this = mcflirtedAfterBlur(this, blur)
            dyn = mlfourd.DynamicNIfTId(this.component_); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.mcflirtedAfterBlur(blur);
            this.component_ = dyn.component_;
        end
        function this = revertFrames(this, origNiid, frames)
            dyn = mlfourd.DynamicNIfTId(this.component_); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.revertFrames(origNiid, frames);
            this.component_ = dyn.component_;
        end
        function this = masked(this, niidMask)
            assert(isa(niidMask, 'mlfourd.INIfTId'));
            this.mask_ = niidMask;
            dyn = mlfourd.DynamicNIfTId(this.component_); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.masked(niidMask);
            this.component_ = dyn.component_;
        end
 	end     
    
    %% PROTECTED
    
    properties (Access = 'protected')
        times_
        taus_
        timeMidpoints_
        header_
        wellMatrix_
        pie_
        mask_
    end
    
    methods (Access = 'protected')
        function this = readRec(this)
            try
                tp = mlio.TextParser.load(this.recFqfilename);
                this = this.readHeader(tp);
                this = this.readSchedule(tp);                
                this = this.readTimes;
                this = this.readTaus;
            catch ME
                handexcept(ME);
            end
        end
        function this = readHeader(this, txtPars)
            this.header_.injectionTime  = txtPars.parseAssignedNumeric('Start time');
            this.header_.numberOfFrames = txtPars.parseColonNumeric('number of frames');
            this.header_.string         = char(txtPars);
        end
        function this = readSchedule(this, txtPars)
            [~,first] = txtPars.findFirstCell('Frame  Start  Duration (sec)'); 
            first = first + 2;
            last = first + this.header.numberOfFrames - 2;
            this.header_.frame    = zeros(1,last-first+1);
            this.header_.start    = zeros(1,last-first+1);
            this.header_.duration = zeros(1,last-first+1);
            for c = first:last
                expr = '(?<frame>\d+\.?\d*)\s+(?<start>-?\d+\.?\d*)\s+(?<duration>\d+\.?\d*)';
                names = regexp(txtPars.cellContents{c}, expr, 'names');
                cc = c - first + 1;
                this.header_.frame(cc)    = str2double(names.frame);
                this.header_.start(cc)    = str2double(names.start);
                this.header_.duration(cc) = str2double(names.duration);
            end
        end
        function this = readTimes(this)
            this.times_ = this.header.start + this.header.injectionTime; % decay corrections must be to time of injection
        end
        function this = readTaus(this)
            this.taus_ = this.header.duration;
        end
        function this = readWellMatrix(this)
            try
                fid = fopen(this.wellFqfilename);
                tmp = textscan(fid, '%f %f %f %f %f');
                this.wellMatrix_ = cell2mat(tmp);
                fclose(fid);
            catch ME
                handexcept(ME);
            end
        end
        function this = setTimeMidpoints(this)
            this.timeMidpoints_ = this.times;
            for t = 2:this.length
                this.timeMidpoints_(t) = (this.times(t-1) + this.times(t))/2;
            end            
        end
        function img  = petCounts2wellCounts(this, img)
            %% PETCOUNTS2WELLCOUNTS; cf. man pie; does not divide out number of pixels.
            
            switch (length(size(img)))
                case 2
                    for t = 1:size(img, 2)
                        img(:,t) = img(:,t) * this.taus(t) * this.pie; % taus in sec <-> taus in min * 60
                    end
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) * this.taus(t) * this.pie; % taus in sec <-> taus in min * 60
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) * this.taus(t) * this.pie; % taus in sec <-> taus in min * 60
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', 'size(EcatExactHRPlus.petCounts2wellCounts.img) -> %s', mat2str(size(img)));
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

