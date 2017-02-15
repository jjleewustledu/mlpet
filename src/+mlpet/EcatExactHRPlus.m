classdef EcatExactHRPlus < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData & mlpet.IWellData
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
        manuallyRecordedPie        
    end
    
    properties (Dependent)
        
        %% IWellData
        
        scanIndex % integer, e.g., last char in 'p1234ho1'
        tracer % char, e.g., 'ho'
        scanDuration % sec   
        header
        
        %% IScannerData
        
        sessionData
        datetime0
        doseAdminDatetime  
 		dt
        time0
        timeF
        timeDuration
        times
        timeMidpoints %% cf. man petproc
        taus
        counts 
        becquerels
        isotope
        efficiencyFactor
        
        %% new 
       
        hdrinfoFqfilename
        mask
        nPixels
        pie
        recFqfilename
        scannerTimeShift
        textParserRec
        tscCounts
        wellFactor
        wellFqfilename
        wellCounts      
        W
    end 

    methods %% GET
        
        %% IWellData
        
        function idx  = get.scanIndex(this)
            names = regexp(this.component.fileprefix, mlpet.PETIO.SCAN_INDEX_EXPR, 'names');
            idx = str2double(names.idx);
        end
        function t    = get.tracer(this)
            names = regexp(this.component.fileprefix, mlpet.PETIO.TRACER_EXPR, 'names');
            t = names.tracer;
        end
        function sd   = get.scanDuration(this)
            assert(~isempty(this.times_));
            sd = this.times_(end);
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
        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function t    = get.datetime0(this)
            t = [];
        end
        function t    = get.doseAdminDatetime(this)
            t = this.header.doseAdminDatetime;
        end
        function g    = get.dt(this)
            if (~isempty(this.dt_))
                g = this.dt_;
                return
            end            
            g = min(this.taus);
        end
        function this = set.dt(this, s)
            assert(isnumeric(s));
            this.dt_ = s;
        end
        function g    = get.time0(this)
            if (~isempty(this.time0_))
                g = this.time0_;
                return
            end            
            g = this.times(1);
        end
        function this = set.time0(this, s)
            assert(isnumeric(s));
            this.time0_ = s;
        end
        function g    = get.timeF(this)
            if (~isempty(this.timeF_))
                g = this.timeF_;
                return
            end            
            g = this.times(end);
        end
        function this = set.timeF(this, s)
            assert(isnumeric(s));
            this.timeF_ = s;
        end
        function g    = get.timeDuration(this)
            g = this.timeF - this.time0;
        end
        function this = set.timeDuration(this, s)
            if (isnumeric(s) && s < this.times(end) - this.time0)
                this.timeF = this.time0 + s;
                return
            end
            warning('mlpet:setPropertyIgnored', 'EcatExactHRPlus.set.timeDuration');
        end
        function t    = get.times(this)
            assert(~isempty(this.times_));
            t = this.times_;
        end
        function this = set.times(this, t)
            assert(isnumeric(t));
            this.times_ = t;
        end
        function tmp  = get.timeMidpoints(this)
            assert(~isempty(this.timeMidpoints_));
            tmp = this.timeMidpoints_;
        end
        function t    = get.taus(this)
            assert(~isempty(this.taus_));
            t = this.taus_;
        end
        function c    = get.counts(this)
            assert(~isempty(this.component.img));
            if (size(this.component.img,4) > length(this.times)) 
                warning('mlpet:unexpectedDataSize', ...
                        'EcatExactHRPlus.get.counts found size(this.component)->%s, length(this.times)->%i', ...
                        num2str(size(this.component)), length(this.times)); 
                this.component.img = this.component.img(:,:,:,1:length(this.times)); 
            end
            c = this.component.img;
            c = double(c);
            c = squeeze(c);
        end
        function this = set.counts(this, c)
            assert(isnumeric(c));
            this.component.img = double(c);
        end
        function b    = get.becquerels(this)
            b = this.petCounts2becquerels(this.counts);
        end
        function i    = get.isotope(this)
            tr = lower(this.tracer);
            
            % N.B. order of testing lstrfind
            if (lstrfind(tr, {'ho' 'oo' 'oc' 'co'}))
                i = '15O';
                return
            end
            if (lstrfind(tr, 'fdg'))
                i = '18F';
                return
            end 
            if (lstrfind(tr, 'g'))
                i = '11C';
                return
            end            
            error('mlpet:indeterminatePropertyValue', ...
                'EcatExactHRPlus.guessIsotope could not recognize the isotope of %s', this.tracer);
        end  
        function e    = get.efficiencyFactor(this)
            e = this.W;
        end
        
        %% new
        
        function fn  = get.hdrinfoFqfilename(this)
            pnum = str2pnum(this.component.fileprefix);
            dtl  = mlsystem.DirTool( ...
                   fullfile(this.component.filepath, '..', '..', 'hdr_backup', sprintf('%sho*.hdrinfo', pnum)));
            fn   = dtl.fqfns{1};
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
        function p   = get.pie(this)
            assert(isnumeric(this.pie_) && ~isempty(this.pie_));
            p = this.pie_;
        end
        function f   = get.recFqfilename(this)
            f = sprintf('%s.img.rec', this.component.fqfileprefix);
            if (~lexist(f)) %%% KLUDGE
                mlbash(sprintf( ...
                    'cp %s/%s%s%i.img.rec %s', ...
                    this.component.filepath, str2pnum(this.component.fileprefix), this.tracer, this.scanIndex, f));
            end
        end
        function t   = get.scannerTimeShift(this)
            t = this.scannerTimeShift_;
        end
        function fp  = get.textParserRec(this)
            fp = this.textParserRec_;
            assert(isa(fp, 'mlio.TextParser'));
        end
        function wc  = get.tscCounts(this)
            wc = this.petCounts2tscCounts(this.counts);
        end
        function wc  = get.wellCounts(this)
            wc = this.petCounts2wellCounts(this.counts);
        end
        function w   = get.wellFactor(this)
            assert(~isempty(this.wellMatrix_), ...
                'DecayCorrection.get.wellFactor:  this.wellMatrix_ was empty');
            w = this.wellMatrix_(5,1); 
        end
        function f   = get.wellFqfilename(this)
            w = sprintf('%s.wel', str2pnum(this.component.fileprefix));
            f = fullfile(this.component.filepath, w);
            g = 0;
            while (~lexist(f, 'file'))
                f = fullfile(fileparts(this.component.filepath), w);
                g = g + 1;
                if (g > this.DEPTH_SEARCH_FOR_WELL && ~lexist(f, 'file'))
                    error('mlpet:IOError:fileNotFound', 'EcatExactHRPlust.get.wellFqfilename:  %s not found', f);
                end
            end
        end      
        function w   = get.W(this)
            w = 60*this.dt*this.pie;
        end
    end
    
    methods (Static)
        function this = load(varargin)
            this = mlpet.EcatExactHRPlus(mlfourd.NIfTId.load(varargin{:}));
        end
        function this = loadSession(sessd, varargin)
            this = mlpet.EcatExactHRPlus.load(varargin{:});
            assert(isa(sessd, 'mlpipeline.ISessionData'))
            this.sessionData_ = sessd;
        end
    end
    
	methods
 		function this = EcatExactHRPlus(cmp, varargin)
            assert(isa(cmp, 'mlfourd.INIfTI'));
            this = this@mlfourd.NIfTIdecoratorProperties(cmp);
            if (nargin == 1 && isa(cmp, 'mlpet.EcatExactHRPlus'))
                this = this.component;
                return
            end
            
            ip = inputParser;
            addParameter(ip, 'sessionData', []);
            addParameter(ip, 'scannerTimeShift', 0, @isnumeric);
            parse(ip, varargin{:});
            this.sessionData_ = ip.Results.sessionData;
            this.scannerTimeShift_ = ip.Results.scannerTimeShift;
            
            this = this.append_descrip('decorated by EcatExactHRPlus');   
            this = this.readRec;
            this = this.readWellMatrix; 
            this = this.setTimeMidpoints;
            this = this.readPie;
            this = this.shiftTimes(this.scannerTimeShift);
        end 
        
        function len  = length(this)
            len = length(this.times);
        end
        function this = save(this)
            this.component.fqfileprefix = sprintf('%s_%s', this.component.fqfileprefix, datestr(now, 30));
            this.component.save;
        end
        function this = saveas(this, fqfn)
            this.component.fqfilename = fqfn;
            this.save;
        end        
        function this = shiftTimes(this, Dt)
            if (0 == Dt); return; end
            if (2 == length(this.component.size))                
                [this.times_,this.component.img] = shiftVector(this.times_, this.component.img, Dt);
                return
            end
            [this.times_,this.component.img] = shiftTensor(this.times_, this.component.img, Dt);
        end
        function [t,this] = timeInterpolants(this, varargin)
            if (~isempty(this.timeInterpolants_))
                t = this.timeInterpolants_;
                return
            end
            
            t = this.time0:this.dt:this.timeF;
            this.timeInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            if (~isempty(this.timeMidpointInterpolants_))
                t = this.timeMidpointInterpolants_;
                return
            end
            
            t = this.time0+this.dt/2:this.dt:this.timeF+this.dt/2;
            this.timeMidpointInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function [t,this] = tauInterpolants(this, varargin)
            if (~isempty(this.tauInterpolants_))
                t = this.tauInterpolants_;
                return
            end
            
            t = this.dt*ones(1, length(this.timeInterpolants)); 
            this.tauInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function c = countInterpolants(this, varargin)
            c  = pchip(this.times, this.counts, this.timeInterpolants);
            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function c = becquerelInterpolants(this, varargin)
            c  = pchip(this.times, this.becquerels, this.timeInterpolants);
            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end        
            
        function this = blurred(this, blur)
            bl = mlfourd.BlurringNIfTId(this.component);
            bl = bl.blurred(blur);
            this.component = bl.component;
        end
        function this = masked(this, msk)
            assert(isa(msk, 'mlfourd.INIfTI'));
            this.mask_ = msk;
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.masked(msk);
            this.component = dyn.component;
        end
        function this = petobs(this)
            this.fileprefix = [this.fileprefix '_obs'];
            
            [~,idx0] = max(this.times >= this.time0);
            [~,idxF] = max(this.times >= this.timeF);
            if (idx0 == idxF)
                this.img = squeeze(this.counts);
                return
            end
            this.img = trapz(this.times(idx0:idxF), this.counts(:,:,:,idx0:idxF), 4);
        end
        function this = timeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.timeSummed;
            this.component = dyn.component;
        end
        function tc   = tscCountInterpolants(this, varargin)
            tc = pchip(this.times, this.tscCounts, this.timeInterpolants);
            
            if (~isempty(varargin))
                tc = tc(varargin{:}); end
        end 
        function this = volumeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.volumeSummed;
            this.component = dyn.component;
            this.component.img = this.component.img';
        end
        function wc   = wellCountInterpolants(this, varargin)
            wc = pchip(this.times, this.wellCounts, this.timeInterpolants);
            
            if (~isempty(varargin))
                wc = wc(varargin{:}); end
        end  

 	end     
    
    %% PROTECTED
    
    properties (Access = 'protected')
        sessionData_
        
        dt_
        time0_
        timeF_
        times_
        timeMidpoints_
        taus_
        timeInterpolants_
        timeMidpointInterpolants_
        tauInterpolants_
        
        header_
        mask_
        pie_
        scannerTimeShift_
        textParserRec_
        wellMatrix_
    end
    
    methods (Access = 'protected')
        function this = readRec(this)
            assert(lexist(this.recFqfilename), ...
                'mlpet.EcatExactHRPlus.readRec:  requires *.img.rec from ecattoanalyze');  
            try
                tp = mlio.TextParser.loadx(this.recFqfilename, '.img.rec');
                this = this.readHeader(tp);
                this = this.readSchedule(tp);                
                this = this.readTimes;
                this = this.readTaus;
                this.textParserRec_ = tp;
            catch ME
                handexcept(ME);
            end
        end
        function this = readHeader(this, txtPars)
            this.header_.doseAdminDatetime  = txtPars.parseAssignedNumeric('Start time');
            this.header_.string         = char(txtPars);
        end
        function this = readSchedule(this, txtPars)
            [~,labelLine] = txtPars.findFirstCell('Frame  Start  Duration (sec)'); 
            c  = labelLine + 2; % skip header lines
            cc = 1;
            expr = '(?<frame>\d+\.?\d*)\s+(?<start>-?\d+\.?\d*)\s+(?<duration>\d+\.?\d*)';
            names = regexp(txtPars.cellContents{c}, expr, 'names');
            while (~isempty(names))
                
                % frames sometimes get aborted at run-time
                % do not pre-allocate this.header_.*                   
                this.header_.frame(cc)    = str2double(names.frame);
                this.header_.start(cc)    = str2double(names.start);
                this.header_.duration(cc) = str2double(names.duration);
                cc = cc + 1;
                c  = c  + 1;
                names = regexp(txtPars.cellContents{c}, expr, 'names');
            end  
            
            % .img.rec time-frames exclude the first frame; following KLUDGE fixes start times
            assert(c > 2, 'EcatExactHRPlus.readSchedule could find adequate schedule information');
            startTimes         = this.header_.start(2:end);
            startTimes(end+1)  = this.header_.start(end) + this.header_.duration(end);
            this.header_.start = startTimes;
            
        end
        function this = readTimes(this)
            this.times_ = this.header.start + this.header.doseAdminDatetime;
            % decay corrections must be to time of injection
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
        function this = readPie(this)
            if (~isempty(this.manuallyRecordedPie))
                this.pie_ = this.manuallyRecordedPie;
                return
            end
            try
                tp = mlio.TextParser.loadx(this.hdrinfoFqfilename, '.hdrinfo');
                this.pie_ = tp.parseAssignedNumeric('Pie Slope');
            catch ME
                handexcept(ME, 'mlpet:fileNotFound', 'EcatExactHRPlus could not find %s', this.hdrinfoFqfilename);
            end
        end
        function this = setTimeMidpoints(this)
            this.timeMidpoints_ = this.times; %% KLUDGE?
            for t = 2:this.length
                this.timeMidpoints_(t) = (this.times(t-1) + this.times(t))/2;
            end            
        end
        function img  = petCounts2becquerels(this, img)
            %% PETCOUNTS2BECQUERELS; cf. man pie; does not divide out number/volume of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = img * this.pie ./ this.taus'; % taus in sec <-> taus in min * 60
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) * this.pie / this.taus(t); % taus in sec <-> taus in min * 60
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) * this.pie / this.taus(t); % taus in sec <-> taus in min * 60
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', 'size(EcatExactHRPlus.petCounts2wellCounts.img) -> %s', mat2str(size(img)));
            end
        end
        function img  = petCounts2wellCounts(this, img)
            %% PETCOUNTS2WELLCOUNTS; cf. man pie; does not divide out number/volume of pixels.
                        
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = img .* this.taus(1:length(img)) * this.pie; % taus in sec <-> taus in min * 60
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
        function img  = petCounts2tscCounts(this, img)
            %% PETCOUNTS2TSCCOUNTS; cf. man pie, mlpet.TSC; does not divide out number/volume of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = img .* 60 * this.pie;
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) * 60 * this.pie;
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) * 60 * this.pie;
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', 'size(EcatExactHRPlus.petCounts2wellCounts.img) -> %s', mat2str(size(img)));
            end
        end
    end
    
    %% DEPRECATED
    
    methods (Hidden)        
        function this = mcflirtedAfterBlur(this, blur)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.mcflirtedAfterBlur(blur);
            this.component = dyn.component;
        end
        function this = withRevertedFrames(this, origNiid, frames)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.withRevertedFrames(origNiid, frames);
            this.component = dyn.component;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

