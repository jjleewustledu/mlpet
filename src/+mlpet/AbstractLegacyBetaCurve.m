classdef AbstractLegacyBetaCurve < mlpet.ILegacyBetaCurve 
	%% ABSTRACTLEGACYBETACURVE 
    
    %  testing SourceTree 2015feb16

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	
    
    properties
        dt = 1 % sec, for timeInterpolants
    end
    
	properties (Dependent)      
        fileprefix
        scanIndex
        filepath
        fqfilename
        scanDuration % sec  
        times
        timeInterpolants
        counts
        countInterpolants
        header
        headerString
        length
    end 
    
    methods %% GET, SET
        function s    = get.fileprefix(this)
            assert(~isempty(this.fileprefix_));
            s = this.fileprefix_;
        end
        function idx  = get.scanIndex(this)
            idx = str2double(this.fileprefix_(end));
        end
        function p    = get.filepath(this)
            assert(~isempty(this.pathname_));
            p = this.pathname_;
        end
        function f    = get.fqfilename(this)
            f = fullfile(this.filepath, [this.fileprefix this.EXTENSION]);
        end
        function sd = get.scanDuration(this)
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
        function s    = get.headerString(this)
            assert(~isempty(this.header_.string));
            s = this.header.string;
        end
        function this = set.headerString(this, s)
            assert(ischar(s));
            this.header_.string = s;
        end
        function l    = get.length(this)
            l = length(this.times);
        end
    end
    
	methods 
        function this = AbstractLegacyBetaCurve(varargin)
            %% ABSTRACTLEGACYBETACURVE
            %  Usage:  this = this@mlpet.AbstractLegacyBetaCurve(fileprefix[, path]);
            %          this = this@mlpet.AbstractLegacyBetaCurve('p1234ho1', '/path/to/p1234data')
            
            p = inputParser;
            addRequired(p, 'fileprefix',            @this.wellFormedStudyId);
            addOptional(p, 'filepath', pwd,      @(x) lexist(x, 'dir'));
            parse(p, varargin{:});
            
            this.fileprefix_  = p.Results.fileprefix;
            this.pathname_ = p.Results.filepath;
        end
        function d = double(this)
            d = this.counts;
        end
        function c = cell(this)
            warning('mlpet:deprecatedMethodFunction', ...
                'AbstractLegacyBetaCurve.cell is deprecated and will be removed in future development');
            c = {this.times this.counts};
        end
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        pathname_
        fileprefix_
        times_
        counts_
        header_
    end
    
    methods (Access = 'protected')        
        function tf = wellFormedStudyId(this, sid)
            tf = true;
            if ( lstrfind(sid, 'test')); return; end
            if (~ischar(sid)); tf = false; return; end
            if ( lstrfind(sid, '/')); tf = false; return; end
            if (~strcmp('p', sid(1))); tf = false; return; end
            if (~lstrfind(sid, this.STUDY_CODES)); tf = false; return; end
            if ( isnan(str2double(sid(2:5)))); tf = false; return; end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

