classdef Decay < handle & mlpet.IDecaying
	%% DECAY  

	%  $Revision$
 	%  was created 14-Oct-2018 19:12:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        activities
        activityUnits
        halflife
 		isdecaying
        isotope
        tracer
        zerotime
        zerodatetime
 	end
    
%    methods (Abstract, Static)
%        this = CreateFromScanId(varargin)
%    end
    
	methods 
        
        %% GET
        
        function g = get.activities(this)
            g = this.activities_;
        end
        function g = get.activityUnits(this)
            g = this.activityUnits_;
        end
        function g = get.isdecaying(this)
            g = this.isdecaying_;
        end
        function g = get.halflife(this)
            g = this.radionucl_.halflife;
        end
        function g = get.isotope(this)
            g = this.radionucl_.isotope;
        end
        function g = get.tracer(this)
            g = this.tracer_;
        end
        function g = get.zerotime(this)
            g = this.zerotime_;
        end
        function     set.zerotime(this, s)
            %% SET.ZEROTIME will adjust zerodatetime & activities for internal consistency.
            
            assert(isscalar(s), 'mlpet:ValueError', 'Decay.set.zerotime.s is a %s', class(s));
            if (this.isdecaying)
                this.activities_ = this.tprod(this.activities_, this.decayFactor(s));
            end
            this.zerodatetime_ = this.zerodatetime_ + seconds(s - this.zerotime_);
            this.zerotime_ = s;            
        end
        function g = get.zerodatetime(this)
            g = this.zerodatetime_;
        end
        
        %%
        
        function a = predictDecay(this, varargin)
            %% PREDICTDECAY predicts introducing decay effects on activity without changing internal state.
            %  Intention is for debugging.
            %  @param tdt is numeric | datetime.
            %  @return predicted activities for tdt.
            
            a = this.tprod(this.activities, this.decayFactor(varargin{:}));
        end
        function a = decayActivities(this, varargin)
            %% DECAYACTIVITIES introduces effects of decay, avoiding double decay.
            %  @param optional times is numeric; default := 0.
            %  @return activities numeric.
            
            if (this.isdecaying)
                a = this.activities_;
                return
            end
            this.activities_ = this.tprod(this.activities_, this.decayFactor(varargin{:}));
            a = this.activities_;
            this.isdecaying_ = true;
        end
        function f = decayFactor(this, varargin)
            %% DECAYFACTOR introduces effects of decay.
            %  @param tdt is numeric | datetime; default := 0.
            %  @return numeric factors.
            %  @throws mlpet:ValueError.
            
            f = this.createFactor(-1, varargin{:});
        end        
        function [a,t] = shiftWorldline(this, varargin)
            %% SHIFTWORLDLINE shifts activities and zerotime w.r.t. time to emulate sampling an AIF or TAC from another
            %  spacetime coordinate.  Activities shifted back in time will have increased amplitude; activities shifted 
            %  forward in time will have decreased amplitude.
            %  @param required a is numeric activity.
            %  @param optional t is numeric time; default := 0:length(a)-1.
            %  @param named shift is numeric as shifted time.  
            
            ip = inputParser;
            addRequired(ip, 'a', @isnumeric);
            addOptional(ip, 't', 0:length(varargin{1})-1, @isnumeric);
            addParameter(ip, 'shift', 0, @isscalar);
            parse(ip, varargin{:});
            
            a = ip.Results.a.*this.decayFactor(ip.Results.shift);
            t = ip.Results.t + ip.Results.shift;            
        end
        function a = predictUndecay(this, varargin)
            %% PREDICTUNDECAY predicts removing decay effects on activity without changing internal state.
            %  Intention is for debugging.
            %  @param tdt is numeric | datetime.
            %  @return predicted activities for tdt.
            
            a = this.tprod(this.activities, this.undecayFactor(varargin{:}));
        end
        function a = undecayActivities(this, varargin)
            %% UNDECAYACTIVITIES removes any effects of decay, avoiding double undecay.
            %  @param optional times is numeric; default := 0.
            %  @return activities numeric.
            
            if (~this.isdecaying)
                a = this.activities_;
                return
            end
            this.activities_ = this.tprod(this.activities_, this.undecayFactor(varargin{:}));
            a = this.activities_;
            this.isdecaying_ = false;
        end        
        function f = undecayFactor(this, varargin)
            %% UNDECAYFACTOR removes any effects of decay.
            %  @param tdt is numeric | datetime; default := 0.
            %  @return numeric factors.
            %  @throws mlpet:ValueError.
            
            f = this.createFactor(1, varargin{:});
        end
        
 		function this = Decay(varargin)
 			%% DECAY
            %  @param activities := nan without assuming physical units.
 			%  @param isdecaying := true.
            %  @param isotope := ''.
            %  @param tracer := ''.
            %  @param zerotime := 0 is scalar.
            %  @param zerodatetime := NaT is a single datetime.
            
            ip = inputParser;
            addParameter(ip, 'activities', nan, @isnumeric);
            addParameter(ip, 'activityUnits', 'counts/s', @ischar);
            addParameter(ip, 'isdecaying', true, @islogical);
            addParameter(ip, 'isotope', '', @ischar);
            addParameter(ip, 'tracer', '', @ischar);
            addParameter(ip, 'zerotime', 0, @isscalar);
            addParameter(ip, 'zerodatetime', NaT, @(x) isdatetime(x) && length(x) == 1);
            parse(ip, varargin{:});
            this.activities_    = ip.Results.activities;
            this.activityUnits_ = ip.Results.activityUnits;
            this.isdecaying_    = ip.Results.isdecaying;
            if (~isempty(ip.Results.isotope))
                this.radionucl_ = mlpet.Radionuclides(ip.Results.isotope);
            else
                this.radionucl_ = mlpet.Radionuclides(ip.Results.tracer);
            end
            this.tracer_ = ip.Results.tracer;
            this.zerotime_ = ip.Results.zerotime;
            this.zerodatetime_ = ip.Results.zerodatetime;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        activities_
        activityUnits_
        isdecaying_
        radionucl_
        tracer_
        zerotime_
        zerodatetime_
    end
    
    methods (Access = private)
        function f = createFactor(this, varargin)
            %% CREATEFACTOR introduces or removes effects of decay.
            %  @param required sgn is numeric.
            %  @param optional tdt is numeric | datetime; default := 0.
            %  @return f is the numeric factor.
            %  @throws mlpet:ValueError.
            
            ip = inputParser;
            addRequired(ip, 'sgn', @isscalar);
            addOptional(ip, 'tdt', 0, @(x) isnumeric(x) || isdatetime(x));
            parse(ip, varargin{:});          
            
            sgn = sign(ip.Results.sgn);
            if (isdatetime(ip.Results.tdt))
                assert(~isnat(this.zerodatetime_), 'mlpet:ValueError', 'Decay.decayFactor');
                deltat = seconds(ip.Results.tdt - this.zerodatetime_);
            else
                deltat = ip.Results.tdt - this.zerotime_;
            end
            f = 2.^(sgn*deltat/this.halflife);
        end
        function p = tprod(~, a, t)
            t = ensureRowVector(t);
            switch (ndims(a))
                case {1,2}
                    p = zeros(size(a));
                    for it = 1:length(t)
                        p(:,it) = a(:,it) * t(it);
                    end
                case 3
                    p = zeros(size(a));
                    for it = 1:length(t)
                        p(:,:,it) = a(:,:,it) * t(it);
                    end
                case 4
                    p = zeros(size(a));
                    for it = 1:length(t)
                        p(:,:,:,it) = a(:,:,:,it) * t(it);
                    end
                otherwise
                    error('mlpet:IndexError', 'Decay.trpod ndims(a)->%i', ndims(a));
            end
        end
    end
    
    %% HIDDEN
    
    methods (Hidden)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

