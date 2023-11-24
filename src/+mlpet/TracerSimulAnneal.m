classdef TracerSimulAnneal < mloptimization.SimulatedAnnealing
	%% TRACERSIMULATEDANNEAL  

	%  $Revision$
 	%  was created 10-Sep-2020 20:00:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        ArteryInterpolated
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

    methods %% GET
        function g = get.ks(this)
            assert(~isempty(this.product_))
            g = this.product_.ks;
        end
    end

	methods	
 		function this = TracerSimulAnneal(varargin)
 			this = this@mloptimization.SimulatedAnnealing(varargin{:});
            
            [this.ks_lower,this.ks_upper,this.ks0] = remapper(this);
            this.ArteryInterpolated = this.model.artery_interpolated;
        end
        
        function disp(this)
            fprintf('\n')
            fprintf(class(this))
            if isempty(this.product_)
                return
            end
            fprintf('initial ks0: '); disp(this.product_.ks0)
            fprintf('est.     ks: '); disp(this.product_.ks)
            fprintf('        sse: '); disp(this.product_.sse)
            fprintf('   exitflag: '); disp(this.product_.exitflag)
            disp(this.product_.output)
            disp(this.product_.output.rngstate)
            disp(this.product_.output.temperature)
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
        function Q = loss(this)
            Q = this.product_.sse;
        end
        function h = plot(this, varargin)
            ip = inputParser;
            addParameter(ip, 'showAif', true, @islogical)
            addParameter(ip, 'xlim', [-10 500], @isnumeric)            
            addParameter(ip, 'ylim', [], @isnumeric)
            addParameter(ip, 'zoom', 4, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.zoom = ipr.zoom;            
            
            ad = mlaif.AifData.instance();
            tBuffer = ad.tBuffer;
            aif = this.dispersedAif(this.ArteryInterpolated, this.Delta);
            h = figure;
            times = this.TimesSampled;
            sampled = this.model.sampled(this.ks, this.Data, aif, times);            
            
            if ipr.zoom > 1
                leg_meas = sprintf('Measurement x%i', ipr.zoom);
            else
                leg_meas = 'Measurement';
            end
            if ipr.zoom > 1
                leg_est = sprintf('estimation x%i', ipr.zoom);
            else
                leg_est = 'estimation';
            end
            if ipr.showAif
                plot(times, ipr.zoom*this.Measurement, ':o', ...
                    times(1:length(sampled)), ipr.zoom*sampled, '-', ...
                    -tBuffer:length(aif)-tBuffer-1, aif, '--') 
                legend(leg_meas, leg_est, 'aif')
            else
                plot(times, ipr.zoom*this.Measurement, 'o', ...
                    times(1:length(sampled)), ipr.zoom*sampled, '-')                
                legend(leg_meas, leg_est)
            end
            if ~isempty(ipr.xlim); xlim(ipr.xlim); end
            if ~isempty(ipr.ylim); ylim(ipr.ylim); end
            xlabel('times / s')
            ylabel('activity / (Bq/mL)')
            annotation('textbox', [.25 .5 .3 .3], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 8, 'LineStyle', 'none')
            dbs = dbstack;
            title(dbs(1).name)
        end 
        function save(this)
            save([this.fileprefix '.mat'], this);
        end
        function saveas(this, fn)
            save(fn, this);
        end
        function this = solve(this, varargin)
            ip = inputParser;
            addRequired(ip, 'loss_function', @(x) isa(x, 'function_handle'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            options_fmincon = optimoptions('fmincon', ...
                'FunctionTolerance', 1e-9, ...
                'OptimalityTolerance', 1e-9);
            if this.visualize_anneal
                options = optimoptions('simulannealbnd', ...
                    'AnnealingFcn', 'annealingboltz', ...
                    'FunctionTolerance', eps, ...
                    'HybridFcn', {@fmincon, options_fmincon}, ...
                    'InitialTemperature', 20, ...
                    'ReannealInterval', 200, ...
                    'TemperatureFcn', 'temperatureexp', ...
                    'Display', 'diagnose', ...
                    'PlotFcns', {@saplotbestx,@saplotbestf,@saplotx,@saplotf,@saplotstopping,@saplottemperature});
            else
                options = optimoptions('simulannealbnd', ...
                    'AnnealingFcn', 'annealingboltz', ...
                    'FunctionTolerance', eps, ...
                    'HybridFcn', {@fmincon, options_fmincon}, ...
                    'InitialTemperature', 20, ...
                    'ReannealInterval', 200, ...
                    'TemperatureFcn', 'temperatureexp');
            end
 			[ks_,sse,exitflag,output] = simulannealbnd( ...
                @(ks__) ipr.loss_function( ...
                        ks__, this.Data, this.ArteryInterpolated, this.TimesSampled, double(this.Measurement)), ...
                        this.ks0, this.ks_lower, this.ks_upper, options);
            
            this.product_ = struct('ks0', this.ks0, 'ks', ks_, 'sse', sse, 'exitflag', exitflag, 'output', output); 
            if ~this.quiet
                fprintfModel(this)
            end
            if this.visualize
                plot(this)
            end
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

