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
        paramList
        paramList2
        descriptionStem % 'LaifTrainer.train' %'AutoradiographyTrainer.train'
        model
    end
    
    properties (Dependent)
        count
        gathered
        mmIds
    end
    
    methods %% GET
        function c = get.count(this)
            c = length(this.gathered_);
        end
        function g = get.gathered(this)
            g = this.gathered_;
        end
        function y = get.mmIds(this)            
            y = {};
            for gi = 1:length(this.gathered_)
                y = [y this.gathered_{gi}.mmid];
            end
        end
    end
    
	methods (Static)
        function this = loadCRVAutoradiography(fn)            
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'A1' 'T0' 'a' 'c1' 'c2' 'c3' 'c4' 'd' 'f' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'CRV Autoradiography';
            this = this.gatherAll;
        end
        function this = loadCRVAutoradiographyTest(fn)            
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'A1' 'T0' 'a' 'c1' 'c2' 'c3' 'c4' 'd' 'f' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized'};
            this.descriptionStem = 'AutoradiographyTester.prepare';
            this.model = 'CRV Autoradiography';
            this = this.gatherAll;
        end
        function this = loadDCVByGammas(fn)            
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'a' 'c1' 'c2' 'c3' 'c4' 'd' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'DCV by Gammas';
            this = this.gatherAll;
        end
        function this = loadCRVDeconv(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'a' 'c1' 'c2' 'c3' 'c4' 'd' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'CRV Deconvolution';
            this = this.gatherAll;
        end
        function this = loadPET(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'Ew' 'f' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'dose' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'PET';
            this = this.gatherAll;
        end
        function this = loadPETHersc(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'PS' 'f' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'dose' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'PET Herscovitch';
            this = this.gatherAll;
        end
        function this = loadBrainWaterKernel(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'a' 'd' 'n' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'LaifTrainer.train';
            this.model = 'Brain Water Kernel';
            this = this.gatherAll;
        end
        function this = loadDSC(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'Ew' 'a' 'd' 'f' 'n' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'dose' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'DSC-based';
            this = this.gatherAll;
        end
        function this = loadDSCTest(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'Ew' 'a' 'd' 'f' 'n' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'dose' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'AutoradiographyTester.prepare';
            this.model = 'DSC-based';
            this = this.gatherAll;
        end
        function this = loadDSCHersc(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'PS' 'a' 'd' 'f' 'n' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'dose' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'AutoradiographyTrainer.train';
            this.model = 'DSC-based Herscovitch';
            this = this.gatherAll;
        end
        function this = loadDSCHerscTest(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'A0' 'PS' 'a' 'd' 'f' 'n' 'p' 'q0' 't0'};
            this.paramList2 = {'Q' 'Q normalized' 'dose' 'mtt_obs' 'mtt_a'};
            this.descriptionStem = 'AutoradiographyTester.prepare';
            this.model = 'DSC-based Herscovitch';
            this = this.gatherAll;
        end
        function this = loadLaif2(fn)
            this = mlpet.AutoradiographyDB.load(fn);
            this.paramList = {'F' 'S0' 'a' 'b' 'd' 'e' 'g' 'n' 't0' 't1'};
            this.paramList2 = {'Q' 'Q normalized'};
            this.descriptionStem = 'LaifTrainer.train';
            this.model = 'Laif2';
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
        function this = append(this, moreGathered)
            this.gathered_ = [this.gathered_ moreGathered];
        end
        function y = getBestFitOf(this, paramIdx)
            y = [];
            for gi = 1:length(this.gathered_)
                y = [y this.gathered_{gi}.bestFit(paramIdx)];
            end
        end
        function stats = getBestFitStatsOf(this, paramIdx)
            bfs = this.getBestFitOf(paramIdx);
            stats = [min(bfs) median(bfs) max(bfs)];
        end
        function y = getFinalOtherOf(this, paramIdx)
            y = [];
            for gi = 1:length(this.gathered_)
                y = [y this.gathered_{gi}.finalOther(paramIdx)];
            end
        end
        function getSummaryPlot(this)
            figure;
            N = ceil(sqrt(numel(this.paramList)));
            for k = 1:numel(this.paramList)
                subplot(N,N, double(k));
                errorbar(this.getBestFitOf(k), 2*this.getStdOf(k), 'x');
                xlabel(sprintf('imaging sessions'));
                ylabel(sprintf('%s metric +/- 2*sigma', this.paramList{k}));
                stats = this.getBestFitStatsOf(k);
                if (length(stats) >= 3)
                    title(sprintf('%s Parameter %s\nmin %g med %g max %g', ...
                                  this.model, this.paramList{k}, stats(1), stats(2), stats(3)));
                else                    
                    title(sprintf('%s Parameter %s', ...
                                  this.model, this.paramList{k}));
                end
            end
        end
        function getSummaryPlot2(this)
            figure;
            N = ceil(sqrt(numel(this.paramList2)));
            for k = 1:numel(this.paramList2)
                subplot(N+1,N, double(k));
                final = this.getFinalOtherOf(k);
                bar(final);
                xlabel(sprintf('imaging sessions'));
                ylabel(sprintf('%s', this.paramList2{k}));
                title(sprintf('%s Parameter %s', ...
                              this.model, this.paramList2{k}));
            end
            if (lstrfind(this.paramList2, 'mtt_obs') && lstrfind(this.paramList2, 'mtt_a'))
                k = numel(this.paramList2) + 1;
                    subplot(N+1,N, double(k));
                    final = this.getFinalOtherOf(k-2) ./ this.getFinalOtherOf(k-1);
                    bar(final);
                    xlabel(sprintf('imaging sessions'));
                    ylabel(sprintf('mtt_obs/mtt_a'));
                    title(sprintf('%s Parameter %s', ...
                                  this.model, 'mtt_obs/mtt_a'));
            end
        end
        function y = getMeanOf(this, paramIdx)
            y = [];
            for gi = 1:length(this.gathered_)
                y = [y this.gathered_{gi}.mean(paramIdx)];
            end
        end
        function y = getStdOf(this, paramIdx)
            y = [];
            for gi = 1:length(this.gathered_)
                y = [y this.gathered_{gi}.std(paramIdx)];
            end
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        gathered_
    end
    
    methods (Access = 'protected')
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
                [fo,idx]  = this.allFinalOther(idx);
                c = struct( ...
                    'descrip', d, ... 
                    'mmid',    this.mmid(d), ...
                    'bestFit', bf, ...
                    'mean',    m, ...
                    'std',     s, ...
                    'finalOther', fo);
        end
        function [d,idx]   = description(this, idx)  
            [d,idx] = this.findNextCell(this.descriptionStem, idx);
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
        function [fo,idx]  = allFinalOther(this, idx)
            for p = 1:length(this.paramList2)
                [fo(p),idx1(p)] = this.finalOther(this.paramList2{p}, idx);
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
        function [fo,idx]  = finalOther(this, pName, idx)
            [fo,idx] = this.rightSideNumeric(sprintf('FINAL STATS %s', pName), idx);
        end
        function m = mmid(~, desc)
            if (lstrfind(desc, 'bayesian_pet'))
                names = regexp(desc, '\w+/(?<id>mm0\d-\w+)/bayesian_pet', 'names');
                m = names.id;
            elseif (lstrfind(desc, 'Arbelaez/GluT'))
                names = regexp(desc, '\w+/(?<pid>p\d\d\d\d)_JJL/PET/scan(?<sid>\d)', 'names');
                m = [names.pid '_scan' names.sid];
            else
                error('mlpet:stringIdentifierNotFound', 'AutoradiographyDB.mmid');
            end
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

