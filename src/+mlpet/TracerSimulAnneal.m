classdef TracerSimulAnneal < mloptimization.SimulatedAnnealing
	%% TRACERSIMULATEDANNEAL  

	%  $Revision$
 	%  was created 10-Sep-2020 20:00:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        artery_interpolated
        ks0
        ks_lower
        ks_upper
        quiet = false
        visualize = false
        visualize_anneal = false
        zoom = 1
    end
    
	properties (Dependent)   
        ks
    end
    
    methods (Static)        
        function conc = slide_fast(conc, Dt)
            %% SLIDE_FAST slides discretized function conc(t) to conc(t - Dt);
            %  @param conc is row vector without NaN.
            %  @param t is row vector with same size as conc.
            %  @param Dt is scalar rounded to integer.
            %
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            
            Dt = round(Dt);
            if Dt == 0
                return
            end
            if Dt < 0
               T_ = length(conc);
               conc_ = conc(end)*ones(1, length(conc));
               conc_(1:T_+Dt) = conc(1-Dt:end);
               conc = conc_;
               return
            end
            conc_ = zeros(size(conc));
            conc_(1+Dt:end) = conc(1:end-Dt);
            conc = conc_;
        end
    end

	methods	
        
        %% GET
        
        function g = get.ks(this)
            g = this.results_.ks;
        end
        
        %%
        
 		function this = TracerSimulAnneal(varargin)
 			this = this@mloptimization.SimulatedAnnealing(varargin{:});
        end
        
        function disp(this)
            fprintf('\n')
            fprintf(class(this))
            if isempty(this.results_)
                return
            end
            fprintf('initial ks0: '); disp(this.results_.ks0)
            fprintf('est.     ks: '); disp(this.results_.ks)
            fprintf('        sse: '); disp(this.results_.sse)
            fprintf('   exitflag: '); disp(this.results_.exitflag)
            disp(this.results_.output)
            disp(this.results_.output.rngstate)
            disp(this.results_.output.temperature)
        end
        function aif1 = dispersedAif(this, aif)
            n = length(aif);
            times = 0:n-1;
            Delta = this.ks(end);
            
            auc0 = trapz(aif);
            aif1 = conv(aif, exp(-Delta*times));
            aif1 = aif1(1:n);
            aif1 = aif1*auc0/trapz(aif1);            
            if any(isnan(aif1))
                aif1 = aif;
            end
        end
        function fprintfModel(this)
            fprintf('Simulated Annealing:\n');            
            for ky = 1:length(this.ks)
                fprintf('\tk%i = %f\n', ky, this.ks(ky));
            end
            fprintf('\tsigma0 = %f\n', this.sigma0);
            for ky = this.map.keys
                fprintf('\tmap(''%s'') => %s\n', ky{1}, struct2str(this.map(ky{1})));
            end
        end
        function h = plot(this, varargin)
            ip = inputParser;
            addParameter(ip, 'showAif', true, @islogical)
            addParameter(ip, 'xlim', [-10 500], @isnumeric)
            addParameter(ip, 'ylim', [], @isnumeric)
            addParameter(ip, 'zoom', 3, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.zoom = ipr.zoom;
            
            RR = mlraichle.RaichleRegistry.instance();
            tBuffer = RR.tBuffer;
            aif = this.dispersedAif(this.artery_interpolated);
            h = figure;
            times = this.times_sampled;
            sampled = this.model.sampled(this.ks, aif, times);
            if ipr.showAif
                plot(times, ipr.zoom*this.Measurement, ':o', ...
                    times(1:length(sampled)), ipr.zoom*sampled, '-', ...
                    -tBuffer:length(aif)-tBuffer-1, aif, '--')
                if ipr.zoom > 1
                    leg_aif = sprintf('aif x%i', ipr.zoom);
                else
                    leg_aif = 'aif';
                end
                legend('measurement', 'estimation', leg_aif)
            else
                plot(times, ipr.zoom*this.Measurement, 'o', ...
                    times(1:length(sampled)), ipr.zoom*sampled, '-')                
                legend('measurement', 'estimation')
            end
            if ~isempty(ipr.xlim); xlim(ipr.xlim); end
            if ~isempty(ipr.ylim); ylim(ipr.ylim); end
            xlabel('times / s')
            ylabel('activity / (Bq/mL)')
            annotation('textbox', [.25 .5 .3 .3], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 7, 'LineStyle', 'none')
            dbs = dbstack;
            title(dbs(1).name)
        end 
        function save(this)
            save([this.fileprefix '.mat'], this);
        end
        function saveas(this, fn)
            save(fn, this);
        end      
        function s = sprintfModel(this)
            s = sprintf('Simulated Annealing:\n');
            for ky = 1:length(this.ks)
                s = [s sprintf('\tk%i = %f\n', ky, this.ks(ky))]; %#ok<AGROW>
            end
            s = [s sprintf('\tsigma0 = %f\n', this.sigma0)];
            for ky = this.map.keys
                s = [s sprintf('\tmap(''%s'') => %s\n', ky{1}, struct2str(this.map(ky{1})))]; %#ok<AGROW>
            end
        end
 	end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function [m,sd] = find_result(this, lbl)
            ks_ = this.ks;
            assert(strcmp(lbl(1), 'k'))
            ik = str2double(lbl(2));
            m = ks_(ik);
            sd = 0;
        end
        function [lb,ub,ks0] = remapper(this)
            for i = 1:this.map.Count
                lbl = sprintf('k%i', i);
                lb(i)  = this.map(lbl).min; %#ok<AGROW>
                ub(i)  = this.map(lbl).max; %#ok<AGROW>
                ks0(i) = this.map(lbl).init; %#ok<AGROW>
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

