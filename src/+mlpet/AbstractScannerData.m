classdef AbstractScannerData < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData & mlfourd.INumerical
	%% ABSTRACTSCANNERDATA 
    %  TODO:  add methods numel, numelMasked

	%  $Revision$
 	%  was created 03-Jan-2018 00:55:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties
        time0Shift = -2 % sec
    end
    
    properties (Dependent)
        times
        taus  
        time0
        timeF
        timeWindow
        datetime0 % start of scan
        index0
        index0Forced
        indexF 
        dt
             
        decayCorrection
        doseAdminDatetime
        isDecayCorrected 
        isotope       
        mask 
        sessionData  
        tracer
        W % legacy notation from Videen
    end    
    
    methods (Static)
        function dt = dicominfo2datetime(info)
            %% DICOMINFO2DATETIME
            %  @param info is struct from dicominfo.
            %  @return dt is datetime.
            
            assert(isstruct(info));
            assert(ischar(info.SeriesDate));
            assert(8 == length(info.SeriesDate));
            
            Y  = uint16(str2double(info.SeriesDate(1:4)));
            M  = uint16(str2double(info.SeriesDate(5:6)));
            D  = uint16(str2double(info.SeriesDate(7:8)));
            [sextet,decimals] = strtok(info.SeriesDate, '.');
            H  = uint8(str2double(sextet(1:2)));
            MI = uint8(str2double(sextet(3:4)));
            S  = uint8(str2double(sextet(5:6)));
            MS = 1000*str2double(decimals);
            dt = datetime(Y, M, D, H, MI, S, MS);
        end
    end
    
	methods 
        
        %% GET, SET
        
        % IAifData
        function g    = get.times(this)
            g = this.timingData_.times;
        end 
        function g    = get.taus(this)
            g = this.timingData_.taus;
        end 
        function g    = get.time0(this)
            g = this.timingData_.time0;
        end
        function this = set.time0(this, s)
            this.timingData_.time0 = s;
        end
        function g    = get.timeF(this)
            g = this.timingData_.timeF;
        end
        function this = set.timeF(this, s)
            this.timingData_.timeF = s;
        end
        function g    = get.timeWindow(this)
            g = this.timingData_.timeWindow;
        end
        function this = set.timeWindow(this, s)
            this.timingData_.timeWindow = s;
        end
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            assert(isdatetime(s));
            this.timingData_.datetime0 = s;
        end
        function g    = get.index0(this)
            g = this.timingData_.index0;
        end
        function this = set.index0(this, s)
            this.timingData_.index0 = s;
        end
        function g    = get.index0Forced(this)
            g = this.sessionData.index0Forced;
        end
        function g    = get.indexF(this)
            g = this.timingData_.indexF;
        end
        function this = set.indexF(this, s)
            this.timingData_.indexF = s;
       end
        function g    = get.dt(this)
            g = this.timingData_.dt;
        end
        function this = set.dt(this, s)
            this.timingData_.dt = s;
        end
        
        function g    = get.decayCorrection(this)
            g = this.decayCorrection_;
        end
        function g    = get.doseAdminDatetime(this)
            g = this.doseAdminDatetime_;
        end
        function this = set.doseAdminDatetime(this, s)
            assert(isa(s, 'datetime'));
            if (isempty(s.TimeZone))
                s.TimeZone = mlkinetics.Timing.PREFERRED_TIMEZONE;
            end
            this.doseAdminDatetime_ = s;
        end
        function g    = get.isDecayCorrected(this)
            g = this.isDecayCorrected_;
        end
        function this = set.isDecayCorrected(this, s)
            assert(islogical(s));
            if (this.isDecayCorrected_ == s)
                return
            end
            if (this.isDecayCorrected_)  
                this.img = this.decayCorrection_.uncorrectedActivities(this.img, this.time0);
            else
                this.img = this.decayCorrection_.correctedActivities(this.img, this.time0);
            end     
            this.isDecayCorrected_ = s;
        end
        function g    = get.isotope(this)
            if (~isempty(this.isotope_))
                g = this.isotope_;
                return
            end
            if (~isempty(this.sessionData) && ~isempty(this.sessionData.isotope))
                g = this.sessionData.isotope;
                return
            end
            g = '';
        end   
        function g    = get.mask(this)
            g = this.mask_;
        end  
        function this = set.mask(this, s)
            assert(isa(s, 'mlfourd.INIfTI') || isa(s, 'mlfourd.ImagingContext'))
            this.mask_ = s;
        end
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.ISessionData'));
            this.sessionData_ = s;
        end      
        function g    = get.tracer(this)
            g = this.get_tracer__;
        end
        function g    = get.W(this)
            g = this.invEfficiency;
        end  
        function this = set.W(this, s)
            this.invEfficiency = s;
        end           

        %%
        
        function dt_  = datetime(this)
            dt_ = this.timingData_.datetime;
        end
        function n    = numel(this)
            n = numel(this.img);
        end
        function n    = numelMasked(this)
            if (isempty(this.mask_))
                n = this.numel;
                return
            end
            if (isa(this.mask_, 'mlfourd.ImagingContext'))
                this.mask_ = this.mask_.niftid;
            end
            assert(isa(this.mask_, 'mlfourd.INIfTI'));
            n = double(sum(sum(sum(this.mask_.img))));            
        end
        function        plot(this)
            if (isscalar(this.img))
                fprintf(this.img);
                return
            end
            if (isvector(this.img))
                plot(this.times, this.img);
                xlabel(sprintf('%s.times', class(this)));
                ylabel(sprintf('%s.img',   class(this)));
                return
            end
            this.view;
        end
        function this = setTime0ToInflow(this)
            sc = this;
            sc = sc.volumeAveraged;
            d2img = diff(pchip(sc.times, sc.img, sc.time0:sc.timeF), 2);            
            [~,t0] = max(d2img > max(d2img)/20);
            this.time0 = max(this.time0, t0 + this.time0Shift);
        end
        function this = shiftTimes(this, Dt)
            if (0 == Dt)
                return; 
            end
            if (2 == length(this.size))                
                [this.timingData_.times,this.img] = shiftVector(this.timingData_.times, this.img, Dt);
                return
            end
            [this.timingData_.times,this.img] = shiftTensor(this.timingData_.times, this.img, Dt);
        end
        function this = shiftWorldlines(this, Dt, varargin)
            %% SHIFTWORLDLINES
            %  @param required Dt, or \Delta t of worldline. 
            %  Dt > 0 => event occurs at later time and further away in space; boluses are smaller and arrive later.
            %  Dt < 0 => event occurs at earlier time and closer in space; boluses are larger and arrive earlier.
            %  @param optional tzero sets the Lorentz coord for decay-correction and uncorrection.
            
            ip = inputParser;
            addParameter(ip, 'tzero', this.time0, @isnumeric);
            parse(ip, varargin{:});
            
            if (0 == Dt)
                return; 
            end
            this.img = this.decayCorrection_.correctedActivities(this.img, ip.Results.tzero);
            this = this.shiftTimes(Dt);            
            this.img = this.decayCorrection_.uncorrectedActivities(this.img, ip.Results.tzero);
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        
        % mlfourd.INumerical
        function this = blurred(this, varargin)
            bn = mlfourd.NumericalNIfTId(this.component);
            bn = bn.blurred(varargin{:});
            this.component_ = bn.component;
        end     
        function this = masked(this, msk)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.masked(msk);
            this.component_ = nn.component;
            this.mask_ = msk;
        end     
        function this = thresh(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.thresh(varargin{:});
            this.component_ = nn.component;
        end
        function this = threshp(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.threshp(varargin{:});
            this.component_ = nn.component;
        end
        function this = timeContracted(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.timeContracted(varargin{:});
            this.component_ = nn.component;
        end        
        function this = timeSummed(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.timeSummed(varargin{:});
            this.component_ = nn.component;
        end
        function this = uthresh(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthresh(varargin{:});
            this.component_ = nn.component;
        end
        function this = uthreshp(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthreshp(varargin{:});
            this.component_ = nn.component;
        end
        function this = volumeAveraged(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.volumeAveraged(varargin{:});
            this.component_ = nn.component;
        end
        function this = volumeContracted(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.volumeContracted(varargin{:});
            this.component_ = nn.component;
        end
        function this = volumeSummed(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.volumeSummed(varargin{:});
            this.component_ = nn.component;
        end
        
 		function this = AbstractScannerData(cmp, varargin)
 			%% ABSTRACTSCANNERDATA
            %  @param named manualData is required
            %  @param named sessionData is required

            if (isa(cmp, 'mlfourd.ImagingContext'))
                cmp = cmp.niftid;
            end
 			this = this@mlfourd.NIfTIdecoratorProperties(cmp);
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'manualData',  [], @(x) isa(x, 'mldata.IManualMeasurements'));
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'doseAdminDatetime', NaT, @(x) isa(x, 'datetime'));
            addParameter(ip, 'mask', this.ones, @(x) isa(x, 'mlfourd.INIfTI') || isa(x, 'mlfourd.ImagingContext'));
            addParameter(ip, 'isotope', '', @ischar);
            parse(ip, varargin{:});
            this.manualData_ = ip.Results.manualData;
            this.sessionData_ = ip.Results.sessionData;
            this.doseAdminDatetime_ = ip.Results.doseAdminDatetime;
            if (isempty(this.doseAdminDatetime_.TimeZone))
                this.doseAdminDatetime_.TimeZone = mlkinetics.Timing.PREFERRED_TIMEZONE;
            end
            this.mask_ = ip.Results.mask;   
            if (isa(ip.Results.mask, 'mlfourd.ImagingContext'))
                this.mask_ = this.mask_.niftid;
            end
            this.isotope_ = ip.Results.isotope;
            
            if (~isempty(this.sessionData) && ~isempty(this.sessionData.region))
                assert(~isempty(this.mask), ...
                    'mlpet:prerequisitParamIsEmpty', 'AbstractScannerData.ctor.this.mask is empty');
                this = this.volumeAveraged(this.mask);
            end            
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        decayCorrection_
        doseAdminDatetime_
        isDecayCorrected_
        isotope_
        dt_
        manualData_
        mask_
        sessionData_        
        taus_
        time0_
        timeF_
        timeInterpolants_
        times_
        timingData_
        W_
    end
    
    methods (Access = protected)
        function img  = activity2counts(this, img)
            %% BECQUERELS2PETCOUNTS; does not divide out number of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = ensureRowVector(img) .* ensureRowVector(this.taus);
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) * this.taus(t);
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) * this.taus(t);
                    end
                otherwise
                    error('mlsiemens:unsupportedArraySize', ...
                          'size(AbstractScannerData.activity2counts.img) -> %s', mat2str(size(img)));
            end
        end
        function img  = counts2activity(this, img)
            %% BECQUERELS2PETCOUNTS; does not divide out number of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = ensureRowVector(img) ./ ensureRowVector(this.taus);
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) / this.taus(t);
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) / this.taus(t);
                    end
                otherwise
                    error('mlsiemens:unsupportedArraySize', ...
                          'size(AbstractScannerData.counts2activity.img) -> %s', mat2str(size(img)));
            end
        end    
        function mi   = interpolateMetric(this, m, varargin)
            mi = this.pchip(this.times, m, this.timeInterpolants);            
            if (~isempty(varargin))
                mi = mi(varargin{:}); end            
        end       
        function sec  = manualDataClocksTimeOffsetMMRConsole(this)
            try
                sec = seconds(this.manualData_.clocks.TimeOffsetWrtNTS____s('mMR console'));
            catch 
                sec = seconds(this.manualData_.clocks.TIMEOFFSETWRTNTS____S('mMR console'));
            end
        end 
        function yi   = pchip(~, x, y, xi)
            %% PCHIP accomodates y with rank <= 4.
            
            lenxi = length(xi);
            if (xi(end) < x(end) && all(x(1:lenxi) == xi)) % xi \subset x
                switch (length(size(y)))
                    case 2
                        yi = y(:,1:lenxi);
                    case 3
                        yi = y(:,:,1:lenxi);
                    case 4
                        yi = y(:,:,:,1:lenxi);
                    otherwise
                        error('mlsiemens:unsupportedArrayShape', 'AbstractScannerData.pchip');
                end
                return
            end
            
            yi = pchip(x, y, xi);
        end
        function g    = get_tracer__(this)
            g = this.sessionData.tracer;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

