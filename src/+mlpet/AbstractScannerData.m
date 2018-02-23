classdef AbstractScannerData < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData & mlfourd.INumerical
	%% ABSTRACTSCANNERDATA 
    %  TODO:  add methods numel, numelMasked

	%  $Revision$
 	%  was created 03-Jan-2018 00:55:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Dependent)
        times
        taus  
        timeMidpoints
        time0
        timeF
        timeDuration
        datetime0
        index0
        indexF 
        dt
        
        sessionData     
        decayCorrection
        doseAdminDatetime
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
        function g    = get.timeMidpoints(this)
            g = this.timingData_.timeMidpoints;
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
        function g    = get.timeDuration(this)
            g = this.timingData_.timeDuration;
        end
        function this = set.timeDuration(this, s)
            this.timingData_.timeDuration = s;
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
        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.sessionData_ = s;
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
                s.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            end
            this.doseAdminDatetime_ = s;
        end
        function g    = get.W(this)
            if (isempty(this.W_))
                g = this.invEfficiency;
                return
            end
            g = this.W_;
        end  
        function this = set.W(this, s)
            assert(isnumeric(s));
            this.W_ = s;
        end  

        %%        
        
        function dt_  = datetime(this)
            dt_ = this.timingData_.datetime;
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end    
        
        % mlfourd.INumerical
        function this = blurred(this, varargin)
            bn = mlfourd.NumericalNIfTId(this.component);
            bn = bn.blurred(varargin{:});
            this.component = bn.component;
        end     
        function this = masked(this, msk)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.masked(msk);
            this.component = nn.component;
            this.mask_ = msk;
        end     
        function this = thresh(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.thresh(varargin{:});
            this.component = nn.component;
        end
        function this = threshp(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.threshp(varargin{:});
            this.component = nn.component;
        end
        function this = timeContracted(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.timeContracted(varargin{:});
            this.component = nn.component;
        end        
        function this = timeSummed(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.timeSummed(varargin{:});
            this.component = nn.component;
        end
        function this = uthresh(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthresh(varargin{:});
            this.component = nn.component;
        end
        function this = uthreshp(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthreshp(varargin{:});
            this.component = nn.component;
        end
        function this = volumeAveraged(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.volumeAveraged(varargin{:});
            this.component = nn.component;
        end
        function this = volumeContracted(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.volumeContracted(varargin{:});
            this.component = nn.component;
        end
        function this = volumeSummed(this, varargin)
            nn = mlfourd.NumericalNIfTId(this.component); 
            nn = nn.volumeSummed(varargin{:});
            this.component = nn.component;
        end
        
 		function this = AbstractScannerData(cmp, varargin)
 			%% ABSTRACTSCANNERDATA
            %  @param named manualData is required
            %  @param named sessionData is required

 			this = this@mlfourd.NIfTIdecoratorProperties(cmp);
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'manualData',  [], @(x) isa(x, 'mldata.IManualMeasurements'));
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'doseAdminDatetime', NaT, @(x) isa(x, 'datetime'));
            addParameter(ip, 'invEfficiency', 1.155, @isnumeric); % from HYGLY28/V2
            addParameter(ip, 'mask', this.ones, @(x) isa(x, 'mlfourd.INIfTI'));
            parse(ip, varargin{:});
            this.manualData_ = ip.Results.manualData;
            this.sessionData_ = ip.Results.sessionData;
            this.doseAdminDatetime_ = ip.Results.doseAdminDatetime;
            if (isempty(this.doseAdminDatetime_.TimeZone))
                this.doseAdminDatetime_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            end
            this.invEfficiency_ = ip.Results.invEfficiency;
            this.mask_ = ip.Results.mask;
            
            this = this.createTimingData;
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        decayCorrection_
        doseAdminDatetime_
        isDecayCorrected_
        dt_
        invEfficiency_
        manualData_
        mask_
        sessionData_        
        taus_
        time0_
        timeF_
        timeMidpoints_
        timeInterpolants_
        timeMidpointInterpolants_
        times_
        timingData_
        W_
    end
    
    methods (Access = protected)
        function this = createTimingData(this)
            this.timingData_ = mldata.TimingData( ...
                'times',     this.sessionData.times, ...
                'datetime0', this.sessionData.readDatetime0 - this.manualDataClocksTimeOffsetMMRConsole);
            if (length(size(this)) < 4)
                return
            end
            if (size(this, 4) == length(this.times))
                return
            end
            if (size(this, 4) < length(this.times)) % trim this.times
                this.times = this.times(1:size(this, 4));
            end
            if (length(this.times) < size(this, 4)) % trim this.img
                this.img = this.img(:,:,:,1:length(this.times));
            end
            warning('mlpet:unexpectedNumel', ...
                'AbstractScannerData.createTiminData:  this.times->%i but size(this,4)->%i', ...
                length(this.times), size(this, 4));
        end
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
            sec = seconds(this.manualData_.clocks.TimeOffsetWrtNTS____s('mMR console'));
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
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

