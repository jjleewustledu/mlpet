classdef AbstractScannerData < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData
	%% ABSTRACTSCANNERDATA 
    %  TODO:  add methods numel, numelMasked

	%  $Revision$
 	%  was created 03-Jan-2018 00:55:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Dependent)
        
        % mlpet.IScannerData
        sessionData
        
        % new      
        mask
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
        function yi = pchip(x, y, xi)
            %% PCHIP accomodates y with rank <= 4.
            
            lenxi = length(xi);
            if (xi(end) < x(end) && all(x(1:lenxi) == xi))
                switch (length(size(y)))
                    case 2
                        yi = y(:,1:lenxi);
                    case 3
                        yi = y(:,:,1:lenxi);
                    case 4
                        yi = y(:,:,:,1:lenxi);
                    otherwise
                        error('mlsiemens:unsupportedArrayShape', 'BiographMMR.pchip');
                end
                return
            end
            yi = pchip(x, y, xi);
        end
    end
    
	methods 
        
        %% GET, SET
        
        % mlpet.IScannerData
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.sessionData_ = s;
        end
        
        % new
        function g    = get.mask(this)
            g = this.mask_;
        end
        
        %%
		  
        % mlpet.IScannerData, mldata.ITimingData
        function ai   = activityInterpolants(this, varargin)
            ai = this.interpolateMetric(this.activity, varargin{:});
        end        
        function ci   = countInterpolants(this, varargin)
            ci = this.interpolateMetric(this.counts, varargin{:});
        end
        function di   = decayInterpolants(this, varargin)
            di = this.interpolateMetric(this.decays, varargin{:});
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
            n = double(sum(sum(sum(this.mask_.img)))); % sum_{x,y,z}, returning nonsingleton t in mask               
        end
        function this = shiftTimes(this, Dt)
            %% SHIFTTIMES provides time-coordinate transformation
            
            if (0 == Dt); return; end
            if (2 == length(this.component.size))                
                [this.times_,this.component.img] = shiftVector(this.times_, this.component.img, Dt);
                return
            end
            [this.times_,this.component.img] = shiftTensor(this.times_, this.component.img, Dt);
        end
        function this = shiftWorldlines(this, Dt)
            %% SHIFTWORLDLINES
            
            if (0 == Dt); return; end        
            this = this.shiftTimes(Dt);
            if (~isempty(this.component.img))
                this.component.img = this.decayCorrection_.adjustCounts(this.component.img, -sign(Dt), Dt);
            end
            error('mlsiemens:incompletelyImplemented', 'AbstractScannerData:shiftWorldlines');
        end
        function sai  = specificActivityInterpolants(this, varargin)
            sai = this.interpolateMetric(this.specificActivity);
        end
        
        % borrowed from mffourd.NumericalNIfTId
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
        
        % others        
        function this = crossCalibrate(this, varargin)
        end
        function len  = length(this)
            len = length(this.times);
        end
        
 		function this = AbstractScannerData(cmp, varargin)
 			%% ABSTRACTSCANNERDATA

 			this = this@mlfourd.NIfTIdecoratorProperties(cmp);
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'mask', [], @(x) isa(x, 'mlfourd.INIfTI'));
            parse(ip, varargin{:});
            this.mask_ = ip.Results.mask;
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        mask_
        sessionData_
        timingData_
    end
    
    methods (Access = protected)        
        function mi = interpolateMetric(this, m, varargin)
            mi = this.pchip(this.times, m, this.timeInterpolants);            
            if (~isempty(varargin))
                mi = mi(varargin{:}); end            
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

