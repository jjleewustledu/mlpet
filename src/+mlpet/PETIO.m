classdef PETIO < mlio.AbstractIO 
	%% PETIO 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties (Dependent)
        scanIndex
        tracer
    end 
    
    methods % GET
        function idx = get.scanIndex(this)
            if (length(this.fileprefix) < 6)
                idx = nan; 
                return
            end
            idx = str2double(this.fileprefix(end));
        end
        function id = get.tracer(this)            
            if (length(this.fileprefix) < 6)
                id = ''; 
                return
            end
            id = this.fileprefix(6:end-1);
        end
    end
    
    methods (Static)
        function load(~)
            error('mlpet:notImplemented', 'PETIO.load');
        end
    end

	methods 
        function this = PETIO(fileLoc)            
            p = inputParser;
            addRequired(p, 'fileLocation', @this.wellFormedFileLocation);
            parse(p, fileLoc);
            
            [p,f,s] = fileparts(p.Results.fileLocation);
            if (isempty(p)); p = pwd; end
            this.filepath   = p;
            this.fileprefix = f;
            this.filesuffix = s;
        end
 		function save(~)
            error('mlpet:notImplemented', 'PETIO.save');
        end         
        function tf = wellFormedFileLocation(this, fileLoc)
            tf = false;
            [p,f,s] = fileparts(fileLoc);
            if (this.wellFormedFilepath(p) && ...
                this.wellFormedFileprefix(f) && ...
                this.wellFormedFilesuffix(s))
                tf = true;
            end
        end
        function tf = wellFormedFilepath(~, p)
            tf = false;
            if (lexist(p, 'dir') || isempty(p))
                tf = true;
            end
        end
        function tf = wellFormedFileprefix(~, f)
            tf = false;
            if ( strcmp(f(1), 'p') && ...
                ~isnan(str2double(f(2:5))))
                tf = true;
            end
            if (lstrfind(f, 'test'))
                tf = true;
            end
        end
        function tf = wellFormedFilesuffix(~, ~)
            tf = true;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

