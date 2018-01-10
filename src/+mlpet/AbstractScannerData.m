classdef AbstractScannerData < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData
	%% ABSTRACTSCANNERDATA  

	%  $Revision$
 	%  was created 03-Jan-2018 00:55:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 	end

    properties (Dependent)
        
        % mlpet.IScannerData, mldata.ITimingData
        sessionData
        
        % new        
        mask
        nPixels
    end    
    
    methods (Static)
        function dt = dicominfo2datetime(info)
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
        
        % mlpet.IScannerData, mldata.ITimingData    
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
        function g    = get.nPixels(this)
            if (isempty(this.mask_))
                g = prod(this.component.size(1:3));
            else
                assert(1 == max(max(max(this.mask_.img))));
                assert(0 == min(min(min(this.mask_.img))));
                g = sum(sum(sum(this.mask_.img)));
            end
        end  
        
        %%
		  
        function di   = decayInterpolants(this, varargin)
            di = this.decays;
            di = this.pchip(this.times, di, this.timeInterpolants);            
            if (~isempty(varargin))
                di = di(varargin{:}); end
        end
        function sai  = specificActivityInterpolants(this, varargin)
            sai = this.specificActivity;
            sai = this.pchip(this.times, sai, this.timeInterpolants);            
            if (~isempty(varargin))
                sai = sai(varargin{:}); end
        end
        
        function ai   = activityInterpolants(this, varargin)
            ai = this.activity;
            ai = this.pchip(this.times, ai, this.timeInterpolants);            
            if (~isempty(varargin))
                ai = ai(varargin{:}); end
        end
        function this = blurred(this, blur)
            bl = mlfourd.BlurringNIfTId(this.component);
            bl = bl.blurred(blur);
            this.component = bl.component;
        end
        function c    = countInterpolants(this, varargin)
            c = this.counts;
            c = this.pchip(this.times, c, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function this = crossCalibrate(this, varargin)
        end
        function len  = length(this)
            len = length(this.times);
        end
        function this = masked(this, msk)
            assert(isa(msk, 'mlfourd.INIfTI'));
            this.mask_ = msk;
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.masked(msk);
            this.component = dyn.component;
        end   
        function this = maskedVolumeAveraged(this, msk)
            this = this.volumeSummed(this.masked(msk));
            this.img = ensureRowVector(this.img / msk.count);
            this.fileprefix = [this.fileprefix '_mvaWith_' msk.fileprefix];
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
            %% SHIFTTIMES provides time-coordinate transformation
            
            if (0 == Dt); return; end
            if (2 == length(this.component.size))                
                [this.times_,this.component.img] = shiftVector(this.times_, this.component.img, Dt);
                return
            end
            [this.times_,this.component.img] = shiftTensor(this.times_, this.component.img, Dt);
        end
        function this = shiftWorldlines(this, Dt)
            
            if (0 == Dt); return; end        
            this = this.shiftTimes(Dt);
            if (~isempty(this.component.img))
                this.component.img = this.decayCorrection_.adjustCounts(this.component.img, -sign(Dt), Dt);
            end
            error('mlsiemens:incompletelyImplemented', 'AbstractScannerData:shiftWorldlines');
        end
        function this = thresh(this, t)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.thresh(t);
            this.component = nn.component;
        end
        function this = threshp(this, p)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.threshp(p);
            this.component = nn.component;
        end
        function this = timeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.timeSummed;
            this.component = dyn.component;
        end
        function this = uthresh(this, u)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthresh(u);
            this.component = nn.component;
        end
        function this = uthreshp(this, p)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthreshp(p);
            this.component = nn.component;
        end
        function this = volumeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.volumeSummed;
            this.component = dyn.component;
        end
        
 		function this = AbstractScannerData(varargin)
 			%% ABSTRACTSCANNERDATA
 			%  Usage:  this = AbstractScannerData()

 			this = this@mlfourd.NIfTIdecoratorProperties(varargin{:});
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        mask_
        sessionData_
        timingData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

