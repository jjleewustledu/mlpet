classdef O15Director 
	%% O15DIRECTOR is the client's director that specifies algorithms for building [15O]-PET imaging objects;
    %  takes part in builder design patterns with concrete O15Builder and others.
	
	%  Version $Revision: 2608 $ was created $Date: 2013-09-07 19:14:08 -0500 (Sat, 07 Sep 2013) $ by $Author: jjlee $,  
 	%  last modified $LastChangedDate: 2013-09-07 19:14:08 -0500 (Sat, 07 Sep 2013) $ and checked into svn repository $URL: file:///Users/jjlee/Library/SVNRepository_2012sep1/mpackages/mlfourd/src/+mlfourd/trunk/O15Director.m $ 
 	%  Developed on Matlab 7.13.0.564 (R2011b) 
 	%  $Id: O15Director.m 2608 2013-09-08 00:14:08Z jjlee $ 
 	%  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad) 
    
    methods (Static)
        function this = load(varargin)
            %% LOAD [15O] image file
            %  this = O15Director.laod(o15_filename[, parameter, parameter_value])
            %                                         ^ 'Hdrinfo', filename
            %                                           'Mask', filename
            
            ip = inputParser;
            addRequired( ip, 'filename',    @(x) lexist(x, 'file'));
            addParameter(ip, 'Hdrinfo', '', @ischar);
            addParameter(ip, 'Mask',    '', @ischar);
            parse(ip, varargin{:});
            
            import mlpet.*;
            switch (O15Director.whichTracer(ip.Results.filename))
                case 'ho'
                    bldr = H15OBuilder.load(ip.Results.filename);
                case 'oo'
                    bldr = O15OBuilder.load(ip.Results.filename);
                case 'oc'
                    bldr = C15OBuilder.load(ip.Results.filename);
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                          'O15Director.load:  whichTracer->%s', O15Director.whichTracer(ip.Results.filename));
            end
            this = O15Director(bldr);
            if (~isempty(ip.Results.Mask))
                this.mask_ = mlfourd.NIfTId.load(ip.Results.Mask); end
            if (~isempty(ip.Results.Hdrinfo))
                this.hdrinfo_ = Hdrinfo.load(ip.Results.Hdrinfo); end
        end
        function id = whichTracer(fname)
            [~,fname] = gzfileparts(fname);
            id = '';
            if (lstrfind(fname, 'ho'))
                id = 'ho'; return; end
            if (lstrfind(fname, 'oo'))
                id = 'oo'; return; end
            if (lstrfind(fname, 'oc'))
                id = 'oc'; return; end
        end
    end
    
    methods
        function n = niftid(this)
            n = this.builder_.niftid;
        end
        function v = vFrac(this)
            v = [];
            if (~isa(this.builder_, 'mlpet.C15OBuilder'))
                return; end
            if (isempty(this.hdrinfo_))
                return; end
            v = this.builder_.maskedAverage(this.mask_) * this.hdrinfo_.bloodVolumeFactor;
            v = v/100;
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        builder_
        mask_
        hdrinfo_
    end
        
    methods (Access = 'protected')
 		function this = O15Director(bldr)
            assert(isa(bldr, 'mlpet.C15OBuilder'));
            this.builder_ = bldr;
        end
    end 
    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

