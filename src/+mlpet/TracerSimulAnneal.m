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
        int_dt_M
        ks
        ks_names
        M0
    end

	methods	%% GET  
        function g = get.int_dt_M(this)
            g = trapz(this.TimesSampled, this.Measurement);
        end
        function g = get.ks(this)
            assert(~isempty(this.product_))
            g = this.product_.ks;
        end
        function g = get.ks_names(this)
            g = this.model.ks_names;
        end
        function g = get.M0(this)
            g = max(this.Measurement);
        end
    end

	methods	        
        function D = Delta(this)
            %% override as needed, e.g., D <- 0

            D = 0;
        end
        function disp(this)
            fprintf('\n')
            fprintf(class(this))
            if isempty(this.product_)
                return
            end
            fprintf('initial ks0: '); disp(this.product_.ks0)
            fprintf('est.     ks: '); disp(this.product_.ks)
            fprintf('       loss: '); disp(this.product_.loss)
            fprintf('   exitflag: '); disp(this.product_.exitflag)
            disp(this.product_.output)
            disp(this.product_.output.rngstate)
            disp(this.product_.output.temperature)
        end
        function aif1 = dispersedAif(~, aif, Delta)
            if isempty(Delta) || Delta <= 0
                aif1 = aif;
                return
            end

            n = length(aif);
            times = 0:n-1;
            
            auc0 = trapz(aif);
            aif1 = conv(aif, exp(-Delta*times));
            aif1 = aif1(1:n);
            aif1 = aif1*auc0/trapz(aif1);            
            if any(isnan(aif1))
                aif1 = aif;
            end
        end
        function fprintfModel(this)
            fprintf('%s:\n', stackstr());
            for ky = 1:length(this.ks)
                fprintf('\t%s = %g\n', this.ks_names{ky}, this.ks(ky));
            end
            fprintf('\tloss = %g\n', this.loss())
            keys = natsort(this.map.keys);
            for ky = 1:length(this.ks)
                fprintf('\tmap(''%s'') => %s\n', this.ks_names{ky}, ...
                    join(struct2str(this.map(keys{ky}), orientation='horz')));
            end
        end
        function h = plot(this, opts)
            %% PLOT 0:length() -> this.dispersedAif();
            %       this.TimesSampled -> this.Measurement;
            %       this.TimesSampled -> this.model.sampled();
            %       
            %  also plot xs{i} -> ys{i};           

            arguments
                this mlpet.TracerSimulAnneal
                opts.activityUnits {mustBeTextScalar} = "Bq/mL"
                opts.tag {mustBeTextScalar} = ""
                opts.xlim {mustBeNumeric} = [-10 500] % sec
                opts.ylim {mustBeNumeric} = []
                opts.xs cell = {} % additional xs to plot
                opts.ys cell = {} % additional ys to plot
                opts.legends cell = {} % of additional xs, ys
                opts.colorArt {mustBeTextScalar} = "#A2142F" % maroon
                opts.colorMeas {mustBeTextScalar} = "#0072BD" % navy
                opts.colorModel {mustBeTextScalar} = "0072BD" % navy
                opts.colors cell = {} % consider #EDB120 ~ mustard
                opts.zoomArt double = 1
                opts.zoomMeas double = 4 
                opts.zoomModel double = 4 
                opts.zooms cell = {}
            end
            assert(length(opts.xs) == length(opts.ys))
            if ~isempty(opts.xs) && isempty(opts.colors)
                opts.colors = repmat("#EDB120", size(opts.xs));
            end
            this.zoom = struct( ...
                'zoomArt', opts.zoomArt, ...
                'zoomMeas', opts.zoomMeas, ...
                'zoomModel', opts.zoomModel, ...
                'zooms', opts.zooms);
            
            % var notations
            %ad = mlaif.AifData.instance();
            %tBuffer = ad.tBuffer;
            TS = this.TimesSampled;
            TSInt = 0:TS(end);
            ArtInt = this.dispersedAif(this.ArteryInterpolated, this.Delta);  
            ArtInt = ArtInt(1:length(TSInt));
            Meas = this.Measurement;
            Model = this.rescaleModelEstimate(this.model.sampled(this.ks, this.Data, ArtInt, TS));
            
            % build legends
            legendCell = {};
            legendCell = [legendCell, sprintf('Arterial x%i', opts.zoomArt)];
            legendCell = [legendCell, sprintf('Measurement x%i', opts.zoomMeas)];
            legendCell = [legendCell, sprintf('Model x%i', opts.zoomModel)];
            legendCell = [legendCell, opts.legends]; % of additional xs, ys

            % plotting implementation
            h = figure;
            hold("on");
            plot(TSInt, opts.zoomArt*ArtInt, '-', LineWidth=2, Color=opts.colorArt)
            plot(TS, opts.zoomMeas*Meas, 'o', MarkerSize=8, Color=opts.colorMeas)
            plot(TS, opts.zoomModel*Model, '--', LineWidth=2, Color=opts.colorMeas)
            for ci = 1:length(opts.xs)
                plot(opts.xs{ci}, opts.ys{ci}, ':', LineWidth=1.5, Color=opts.colors{ci})
            end
            legend(legendCell);
            if ~isempty(opts.xlim); xlim(opts.xlim); end
            if ~isempty(opts.ylim); ylim(opts.ylim); end
            xlabel('times / s')
            ylabel(sprintf('activity / (%s)', opts.activityUnits))
            annotation('textbox', [.25 .5 .3 .3], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 10, 'LineStyle', 'none')
            opts.tag = strrep(opts.tag, "_", " ");
            title([stackstr(use_spaces=true)+";"; string(opts.tag); ""], FontSize=6, Interpreter="none")
            hold("off");
            set(h, position=[300,100,1000,618])
        end 
        function est = rescaleModelEstimate(this, est, opts)
            arguments
                this mloptimization.SimulatedAnnealing
                est {mustBeNumeric}
                opts.norm {mustBeTextScalar} = "max"
            end

            if strcmpi(opts.norm, "max")
                %est = est/max(est);
                est = this.M0*est;
                return
            end

            % rescale by this.int_dt_M
            %est = est/max(est); % for floating-point density
            int_dt_est = trapz(this.TimesSampled, est);
            est = est*this.int_dt_M/int_dt_est;
        end
        function this = solve(this, loss_function)
            %% Args:
            %      this mlpet.TracerSimulAnneal
            %      loss_function function_handle
            
            arguments
                this mlpet.TracerSimulAnneal
                loss_function function_handle
            end
            
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
 			[ks_,loss,exitflag,output] = simulannealbnd( ...
                @(ks__) loss_function( ...
                        ks__, this.Data, this.ArteryInterpolated, this.TimesSampled, double(this.Measurement)), ...
                        this.ks0, this.ks_lower, this.ks_upper, options);
            
            this.product_ = struct('ks0', this.ks0, 'ks', ks_, 'loss', loss, 'exitflag', exitflag, 'output', output); 
            if ~this.quiet
                fprintfModel(this)
            end
            if this.visualize
                plot(this)
            end
        end
        function s = sprintfModel(this)
            s = sprintf('%s:\n', stackstr());
            for ky = 1:length(this.ks)
                s = [s sprintf('\t%s = %g\n', this.ks_names{ky}, this.ks(ky))]; %#ok<AGROW>
            end
            s = [s sprintf('\tloss = %g\n', this.loss())];
            keys = natsort(this.map.keys);
            for ky = 1:length(this.ks)
                s = [s sprintf('\tmap(''%s'') => %s\n', this.ks_names{ky}, ...
                    join(struct2str(this.map(keys{ky}), orientation='horz')))]; %#ok<AGROW>
            end
        end

 		function this = TracerSimulAnneal(varargin)
 			this = this@mloptimization.SimulatedAnnealing(varargin{:});
            
            [this.ks_lower,this.ks_upper,this.ks0] = remapper(this);
            this.ArteryInterpolated = asrow(this.model.artery_interpolated);
        end
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
    
    %% PROTECTED
    
    methods (Access = protected)
        function [m,sd] = find_result(this, lbl)
            re = regexp(lbl, "[a-zA-Z](?<digits>\d+)", "names");
            ik = str2double(re.digits);
            if ik <= length(this.ks)
                m = this.ks(ik);
                sd = 0;
            else
                m = nan;
                sd = nan;
            end
        end
        function [lb,ub,ks0] = remapper(this)
            lb = zeros(size(this.map.keys));
            ub = zeros(size(this.map.keys));
            ks0 = zeros(size(this.map.keys));
            for i = 1:this.map.Count
                lbl = sprintf('k%i', i);
                lb(i) = this.map(lbl).min;
                ub(i) = this.map(lbl).max;
                ks0(i) = this.map(lbl).init;
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

