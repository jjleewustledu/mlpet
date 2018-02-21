classdef AbstractScannerData < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData & mlfourd.INumerical
	%% ABSTRACTSCANNERDATA 
    %  TODO:  add methods numel, numelMasked

	%  $Revision$
 	%  was created 03-Jan-2018 00:55:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Dependent)        
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
        
        %%		  
        
        % mlfourd.INumerical
        function this = blurred(this, varargin)
            bn = mlfourd.BlurringNIfTId(this.component);
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

 			this = this@mlfourd.NIfTIdecoratorProperties(cmp);
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'mask', [], @(x) isa(x, 'mlfourd.INIfTI') || isempty(x));
            parse(ip, varargin{:});
            this.mask_ = ip.Results.mask;
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        decayCorrection_
        dt_
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

