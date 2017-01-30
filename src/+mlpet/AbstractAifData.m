classdef AbstractAifData < mlpet.IAifData & mlio.IOInterface
	%% ABSTRACTAIFDATA
    %  Yet abstract:  counts, becquerels

	%  $Revision$
 	%  was created 29-Jan-2017 18:46:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties (Dependent)
        
        %% IAifData
        
        sessionData
 		dt
        time0
        timeF
        times
        
        %% IOInterface
        
        filename
        filepath
        fileprefix 
        filesuffix
        fqfilename
        fqfileprefix
        fqfn
        fqfp        
    end
    
    methods %% GET, SET
        
        %% IAifData
        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.sessionData_ = s;
        end        
        function g    = get.dt(this)
            if (~isempty(this.dt_))
                g = this.dt_;
                return
            end            
            g = min(this.times(2:end) - this.times(1:end-1))/2;
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
        function t    = get.times(this)
            assert(~isempty(this.times_));
            t = this.times_;
        end
        function this = set.times(this, t)
            assert(isnumeric(t));
            this.times_ = t;
        end
        
        %% IOInterface
        
        function f = get.filename(this)
            f = this.petio_.filename;
        end
        function f = get.filepath(this)
            f = this.petio_.filepath;
        end
        function f = get.fileprefix(this)
            f = this.petio_.fileprefix;
        end
        function f = get.filesuffix(this)
            f = this.petio_.filesuffix;
        end
        function f = get.fqfilename(this)
            f = this.petio_.fqfilename;
        end
        function f = get.fqfileprefix(this)
            f = this.petio_.fqfileprefix;
        end
        function f = get.fqfn(this)
            f = this.petio_.fqfn;
        end
        function f = get.fqfp(this)
            f = this.petio_.fqfp;
        end
    end

	methods 
 		function this = AbstractAifData(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;
            this.petio_ = mlpet.PETIO(this.sessionData.aif('typ', 'fqfn'));
        end
        
        %% IAifData
        
        function [t,this] = timeInterpolants(this, varargin)
            if (~isempty(this.timesInterpolants_))
                t = this.timesInterpolants_;
                return
            end
            
            t = this.time0:this.dt:this.timeF;
            this.timesInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function c = countInterpolants(this, varargin)
            c = pchip(this.times, this.counts, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function b = becquerelInterpolants(this, varargin)
            b = pchip(this.times, this.becquerels, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end        
        
        %% IOInterface
        
        function c = char(this)
            c = this.fqfilename;
        end
        
        %% new
        
        function i = guessIsotope(this)
            tr = lower(this.sessionData.tracer);
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
                'AbstractAifData.guessIsotope could not recognize the isotope of %s', this.sessionData.tracer);
        end 
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
        dt_
        time0_
        timeF_
        times_   
        timesInterpolants_
    end
    
    %% PRIVATE
    
    properties (Access = private)
        petio_
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

