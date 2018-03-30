classdef EcatLogParser  < mlio.LogParser  
	%% ECATLOGPARSER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.6.0.232648 (R2015b) 
 	%  $Id$ 
 	 

	properties (SetAccess = 'protected')
        ecatFilename
        scanDate
        scanTime
    end 
    
    methods (Static)        
        function this = load(fn)
            assert(lexist(fn, 'file'));
            [pth, fp, fext] = fileparts(fn); 
            import mlpet.*;
            if (lstrfind(fext, EcatLogParser.FILETYPE_EXT) || isempty(fext))
                this = EcatLogParser.loadText(fn); 
                this.filepath_   = pth;
                this.fileprefix_ = fp;
                this.filesuffix_ = fext;
                return 
            end
            error('mlpet:unsupportedParam', 'EcatLogParser.load does not support file-extension .%s', fext);
        end
        function this = loadx(fn, ext)
            if (~lstrfind(fn, ext))
                if (~strcmp('.', ext(1)))
                    ext = ['.' ext];
                end
                fn = [fn ext];
            end
            assert(lexist(fn, 'file'));
            [pth, fp, fext] = filepartsx(fn, ext); 
            this = mlpet.EcatLogParser.loadText(fn);
            this.filepath_   = pth;
            this.fileprefix_ = fp;
            this.filesuffix_ = fext;
        end
    end

	methods
    end 
    
    %% PROTECTED
    
    methods (Static, Access = 'protected')
        function this = loadText(fn)
            import mlpet.*;
            this = EcatLogParser;
            this.cellContents_ = EcatLogParser.textfileToCell(fn);                      
            this = this.parseVLine(this.findVLine);
        end
    end
    
    methods (Access = 'protected')
        function this = parseVLine(this, textLine)
            EXPR = '\S*(?<vname>p\d\d\d\d\S+.v)\s+(?<vdate>\d+/\d+/\d+),\s+(?<vtime>\d+:\d+):\d+';
            if (lstrfind(textLine, '.v '))
                names = regexp(textLine, EXPR, 'names');
                this.ecatFilename = names.vname;
                this.scanDate     = names.vdate;
                this.scanTime     = names.vtime;
            else
                error('mlpet:stringIdentifierNotFound', 'EcatLogParser.vLine');
            end
        end
        function contnt = findVLine(this)
            idx = 1; contnt = '';
            while (isempty(contnt))
                [~,idx] = this.findNextCell('------------------------------------------------', idx); 
                idx = idx+1;
                if (lstrfind(this.cellContents_{idx}, '.v '))
                    contnt = this.cellContents_{idx};
                end
            end  
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

