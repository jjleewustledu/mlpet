classdef AbstractWellData < mlpet.IWellData   
	%% ABSTRACTWELLDATA   
    %  Yet abstract:  static method load, method save

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    properties
        dt = 1 % sec, for timeInterpolants
        useBequerels = false % boolean for dividing accumulated counts by sampling durations of each time-frame to obtain 1/sec  
    end
    
	properties (Dependent)        
        filename
        filepath
        fileprefix 
        filesuffix
        fqfilename
        fqfileprefix
        fqfn
        fqfp
        noclobber
        
        scanIndex   
        tracer
        length
        scanDuration % sec  
        times
        timeInterpolants
        counts
        countInterpolants
        header
        
        taus
        timeMidpoints
    end 
    
    methods %% GET, SET 
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
        function f = get.noclobber(this)
            f = this.petio_.noclobber;
        end
        
        function idx  = get.scanIndex(this)
            idx = this.petio_.scanIndex;
        end
        function id  = get.tracer(this)
            id = this.petio_.tracer;
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
        function t    = get.timeInterpolants(this)
            assert(~isempty(this.times_));
            t = this.times_(1):this.dt:this.times_(end);
        end
        function c    = get.counts(this)
            assert(~isempty(this.counts_));
            c = this.counts_;
        end
        function this = set.counts(this, c)
            assert(isnumeric(c));
            this.counts_ = c;
        end
        function c    = get.countInterpolants(this)
            assert(~isempty(this.counts_));
            c = spline(this.times_, this.counts_, this.timeInterpolants);
            c = c(1:length(this.timeInterpolants));
        end
        function h    = get.header(this)
            assert(~isempty(this.header_));
            h = this.header_;
        end
        function this = set.header(this, h)
            if (isstruct(h))
                this.header_ = h; end            
        end
        
        function t = get.taus(this)
            assert(~isempty(this.taus_));
            t = this.taus_;
        end
        function tmp = get.timeMidpoints(this)
            tmp = this.times;
            for t = 2:this.length
                tmp(t) = (this.times_(t-1) + this.times_(t))/2;
            end
        end
    end
    
	methods 
        function this = AbstractWellData(fileLoc)
            %% ABSTRACTWELLDATA
            %  Usage:  this = this@mlpet.AbstractWellData(file_location);
            %          this = this@mlpet.AbstractWellData('/path/to/p1234data/p1234ho1.crv')
            %          this = this@mlpet.AbstractWellData('/path/to/p1234data/p1234ho1')
            %          this = this@mlpet.AbstractWellData('p1234ho1')
            
            this.petio_ = mlpet.PETIO(fileLoc);
        end
        function this = saveas(this, fqfn)
            this.petio_.fqfilename = fqfn;
            this.save;
        end
        function i = guessIsotope(this)
            if (lstrfind(this.tracer, {'ho' 'oo' 'oc' 'co'}))
                i = '15O';
                return
            end
            if (lstrfind(this.tracer, 'g'))
                i = '11C';
                return
            end            
            error('mlpet:indeterminatePropertyValue', ...
                'AbstractWellData.guessIsotope could not recognize the isotope of %s', this.fileprefix);
        end
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        petio_
        
        times_
        taus_
        counts_
        header_
    end     

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

