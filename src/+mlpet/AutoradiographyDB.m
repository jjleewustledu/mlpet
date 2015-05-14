classdef AutoradiographyDB < mlio.LogParser
	%% AUTORADIOGRAPHYDB   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 
    properties 
        paramList = {'A0' 'PS' 'a' 'd' 'f' 'p' 'q0' 't0'};
    end
    
    properties (Dependent)
        gathered
    end
    
    methods %% GET
        function g = get.gathered(this)
            g = this.gathered_;
        end
    end
    
	methods (Static)
        function this = loadPET(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'Ew' 'f' 't0'};
            this = this.gatherAll;
        end
        function this = loadPETHersc(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'PS' 'f' 't0'};
            this = this.gatherAll;
        end
        function this = loadDSC(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'Ew' 'a' 'd' 'f' 'p' 'q0' 't0'};
            this = this.gatherAll;
        end
        function this = loadDSCHersc(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'PS' 'a' 'd' 'f' 'p' 'q0' 't0'};
            this = this.gatherAll;
        end
        function this = load(fn)
            assert(lexist(fn, 'file'));
            [pth, fp, fext] = fileparts(fn); 
            import mlpet.*;
            if (lstrfind(fext, AutoradiographyDB.FILETYPE_EXT) || isempty(fext))
                this = AutoradiographyDB.loadText(fn); 
                this.filepath_   = pth;
                this.fileprefix_ = fp;
                this.filesuffix_ = fext;
                return 
            end
            error('mlpet:unsupportedParam', 'AutoradiographyDB.load does not support file-extension .%s', fext);
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
            this = mlpet.AutoradiographyDB.loadText(fn);
            this.filepath_   = pth;
            this.fileprefix_ = fp;
            this.filesuffix_ = fext;
        end
    end
    
	methods
        function [d,idx]   = description(this, idx)  
            [d,idx] = this.findNextCell('AutoradiographyTrainer.train', idx);
        end
        function [bf,idx]  = allBestFit(this, idx)
            for p = 1:length(this.paramList)
                [bf(p),idx1(p)] = this.bestFit(this.paramList{p}, idx);
            end
            idx = max(idx1);
        end
        function [m,s,idx] = allFinalStats(this, idx)
            for p = 1:length(this.paramList)
                [m(p),s(p),idx1(p)] = this.finalStats(this.paramList{p}, idx);
            end
            idx = max(idx1);
        end
        function [bf,idx]  = bestFit(this, pName, idx)
            [bf,idx] = this.rightSideNumeric(sprintf('BEST-FIT    param  %2s value', pName), idx);
        end
        function [m,s,idx] = finalStats(this, pName, idx)    
            [vals,idx] = this.rightSideNumeric2(sprintf('FINAL STATS param  %2s mean', pName), 'std', idx);
            m = vals(1);
            s = vals(2);
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        gathered_
    end
    
    methods %(Access = 'protected')
        function this = gatherAll(this)
            idx = 1; gi = 1;
            while (idx < this.length)
                try
                    [this.gathered_{gi},idx] = this.gatherCase(idx);
                    gi = gi + 1;
                catch ME %#ok<NASGU>
                    break
                end              
            end
        end
        function [c,idx] = gatherCase(this, idx)
                [d,idx]   = this.description(idx);
                [bf,idx]  = this.allBestFit(idx);
                [m,s,idx] = this.allFinalStats(idx);  
                c = struct( ...
                    'descrip', d, ... 
                    'mmid',    this.mmid(d), ...
                    'bestFit', bf, ...
                    'mean',    m, ...
                    'std',     s);
                    %'params',  this.paramList, ...
        end
        function m = mmid(~, desc)
            names = regexp(desc, '\w+/(?<id>mm0\d-\w+)/bayesian_pet', 'names');
            m = names.id;
        end
    end
    
    methods (Static, Access = 'protected')
        function this = loadText(fn)
            import mlpet.*;
            this = AutoradiographyDB;
            this.cellContents_ = AutoradiographyDB.textfileToCell(fn);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

