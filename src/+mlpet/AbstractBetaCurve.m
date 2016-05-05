classdef (Abstract) AbstractBetaCurve < mlpet.IBetaCurve & mlio.IOInterface 
	%% ABSTRACTBETACURVE 
    %  Yet abstract:  static method load, method save

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	
    
    properties
        dt = 1 % sec, for timeInterpolants
        useBecquerels = false % boolean for dividing accumulated counts by sampling durations of each time-frame to obtain 1/sec  
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
        counts        
        wellCounts
        wellFqfilename
        wellFactor
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
        function c    = get.counts(this)
            assert(~isempty(this.counts_));
            c = this.counts_;
        end
        function this = set.counts(this, c)
            assert(isnumeric(c));
            this.counts_ = c;
        end
        function wc  = get.wellCounts(this)
            wc = this.betaCounts2wellCounts(this.counts);
        end        
        function f = get.wellFqfilename(this)
            fns = { sprintf('%s.wel', this.petio_.fqfileprefix) ...
                    sprintf('%s.wel', this.petio_.fqfileprefix(1:end-1)) ...
                    sprintf('%s.wel', fullfile(this.petio_.filepath,       str2pnum(this.petio_.fileprefix))) ...                    
                    sprintf('%s.wel', fullfile(this.petio_.filepath, '..', str2pnum(this.petio_.fileprefix))) }; %% KLUDGE
            for n = 1:length(fns)
                if (lexist(fns{n}, 'file'))
                    f = fns{n};
                    return
                end
            end
            error('mlpet:fileNotFound', ...
                  'AbstractBetaCurve.wellFqfilename not found among:\n\t%s', cell2str(fns, 'AsRow', true));
        end
        function w = get.wellFactor(this)
            assert(~isempty(this.wellMatrix_), ...
                'DecayCorrection.get.wellFactor:  this.wellMatrix_ was empty');
            w = this.wellMatrix_(5,1); 
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
        function this = AbstractBetaCurve(fileLoc)
            %% ABSTRACTBETACURVE
            %  Usage:  this = this@mlpet.AbstractBetaCurve(file_location);
            %          this = this@mlpet.AbstractBetaCurve('/path/to/p1234data/p1234ho1.crv')
            %          this = this@mlpet.AbstractBetaCurve('/path/to/p1234data/p1234ho1')
            %          this = this@mlpet.AbstractBetaCurve('p1234ho1')
            
            this.petio_ = mlpet.PETIO(fileLoc);          
            this = this.readWellMatrix;
        end
        function c    = char(this)
            c = this.fqfilename;
        end
        function this = saveas(this, fqfn)
            this.petio_.fqfilename = fqfn;
            this.save;
        end
        function i    = guessIsotope(this)
            if (lstrfind(this.fileprefix, 'test'))
                i = '15O';
                return
            end
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
        function t    = timeInterpolants(this, varargin)
            assert(~isempty(this.times_));
            t = this.times_(1):this.dt:this.times_(end);
            
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function c    = countInterpolants(this, varargin)
            assert(~isempty(this.counts_));
            c = pchip(this.times_, this.counts_, this.timeInterpolants);
            c = c(1:length(this.timeInterpolants));
            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function wc   = wellCountInterpolants(this, varargin)
            wc = pchip(this.times, this.wellCounts, this.timeInterpolants);
            wc = wc(1:length(this.timeInterpolants));
            
            if (~isempty(varargin))
                wc = wc(varargin{:}); end
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        petio_        
        times_
        taus_
        counts_
        header_
        wellMatrix_
    end
    
    methods (Access = 'protected')
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
        function curve  = betaCounts2wellCounts(this, curve)
            %% PETCOUNTS2WELLCOUNTS; cf. man pie; does not divide out number of pixels.

            for t = 1:length(curve)
                curve(t) = this.wellFactor * curve(t); % taus in sec
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

