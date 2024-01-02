classdef (Abstract) InputFuncDevice < handle & mlpet.AbstractDevice
    %% contrasts with mlpet.ScannerDevice.
    %  
    %  Created 16-Dec-2023 22:24:31 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    methods
        function ff = new_fqfp(this, opts)
            %% seeks out pertinent fqfp in derivatives, not sourcedata

            arguments
                this mlpet.InputFuncDevice
                opts.remove_substring {mustBeTextScalar} = "_timeAppend-4"
            end

            %assert(contains(this.filepath, "derivatives"))
            %assert(~contains(this.filepath, "sourcedata"))
            fp = mlpipeline.Bids.adjust_fileprefix(this.fileprefix, ...                
                new_proc=stackstr(3, use_dashes=true), new_mode="inputfunc", remove_substring=opts.remove_substring);
            ff = fullfile(this.filepath, fp);
            if contains(ff, "*")
                ff = mglob(ff);
                assert(~isempty(ff))
                if numel(ff) > 1
                    warning("mlaif:RuntimeWarning", stackstr()+" returned string array of length "+numel(ff))
                end
            end
        end
        function g = new_fqfileprefix(this, varargin)
            g = this.fqfp(varargin{:});
        end
        function save(this)
            fqfn = this.new_fqfp + ".mat";
            this.saveas(fqfn);
        end
        function saveas(this, fn)
            save(fn, "this");
        end
    end

    methods (Static)
        function [arterialDev,arterialDatetimePeak] = alignArterialToReference(opts)

            arguments
                opts.arterialDev mlpet.InputFuncDevice
                opts.referenceDev mlpet.AbstractDevice
                opts.sameWorldline logical = false % enforce physical worldline
            end            
            copts = namedargs2cell(opts);

            if isa(opts.referenceDev, "mlpet.ScannerDevice")
                [arterialDev,arterialDatetimePeak] = ...
                    mlpet.InputFuncDevice.alignArterialToScanner(copts{:});
                return
            end
            if isa(opts.referenceDev, "mlpet.InputFuncDevice")
                [arterialDev,arterialDatetimePeak] = ...
                    mlpet.InputFuncDevice.alignArterialToInputFunc(copts{:});
                return
            end
            error("mlpet:RuntimeError", stackstr());
        end
        function [arterialDev,arterialDatetimePeak] = alignArterialToInputFunc(opts)
            %% ALIGNARTERIALTOINPUTFUNC
            %  @param arterialDev is counting device or arterial sampling device, as mlpet.InputFuncDevice.
            %  @param referenceDev is another InputFuncDevice, e.g., an IDIF.
            %  @param sameWorldline is logical.  Set true to avoid worldline shifts between arterial & scanner data.
            %  @return arterialDev, modified if not sameWorldline;
            %  @return arterialDatetimePeak, updated with alignments.
            %  @return arterialDev.Dt, always updated.

            arguments
                opts.arterialDev mlpet.InputFuncDevice
                opts.referenceDev mlpet.InputFuncDevice
                opts.sameWorldline logical = false % enforce physical worldline
            end

            ad = mlaif.AifData.instance();
            arterialDev = copy(opts.arterialDev);
            referenceDev = copy(opts.referenceDev);

            % find Dt of carotid bolus from radial-artery bolus, unresolved frames-of-reference
            unifTimes = 0:max(arterialDev.timeWindow, referenceDev.timesMid(end));
            arterialDevTimes = arterialDev.times(arterialDev.index0:arterialDev.indexF) - arterialDev.time0;
            arterialAct = interp1(arterialDevTimes, ...
                                 arterialDev.activityDensity(), ...
                                 unifTimes);
            referenceAct = interp1(referenceDev.timesMid, ...
                                referenceDev.activityDensity(), ...
                                unifTimes);

            thresh = 0.9; %arterialDev.threshOfPeak;
            [~,idxReference] = max(referenceAct > thresh*max(referenceAct));
            [~,idxArterial] = max(arterialAct > thresh*max(arterialAct));
            tArterial = seconds(unifTimes(idxArterial));
            tReference = seconds(unifTimes(idxReference));
            
            % manage failures of interp1()
            if tArterial > seconds(0.5*referenceDev.timeWindow)
                warning('mlpet:ValueError', ...
                    '%s.tArterial was %g but referenceDev.timeWindow was %g.\n', ...
                    stackstr(), seconds(tArterial), arterialDev.timeWindow)
                ad.stableToInterpolation = false;
                [~,idxArterial] = max(arterialDev.activityDensity() > thresh*max(arterialDev.activityDensity()));
                tArterial = seconds(arterialDevTimes(idxArterial));
                fprintf('tArterial forced-> %g\n', seconds(tArterial))
            end            
            if tArterial > seconds(0.5*referenceDev.timeWindow) %%% UNRECOVERABLE
                error('mlpet:ValueError', ...
                    '%s.tArterial was %g but arterialDev.timeWindow was %g.', ...
                    stackstr(), seconds(tArterial), arterialDev.timeWindow)
            end
            if tReference > seconds(0.75*referenceDev.timeWindow)
                warning('mlpet:ValueError', ...
                    '%s.tScanner was %g but scannerDev.timeWindow was %g.\n', ...
                    stackstr(), seconds(tReference), referenceDev.timeWindow)
                ad.stableToInterpolation = false;
                scannerDevAD = referenceDev.activityDensity('volumeAveraged', true, 'diff', true);
                [~,idxReference] = max(scannerDevAD > thresh*max(scannerDevAD));
                tReference = seconds(referenceDev.timesMid(idxReference));
                fprintf('tScanner forced -> %g\n', seconds(tReference))
            end
            if tReference > seconds(0.75*referenceDev.timeWindow) %%% UNRECOVERABLE
                error('mlpet:ValueError', ...
                    '%s.tScanner was %g but scannerDev.timeWindow was %g.', ...
                    stackstr(), seconds(tReference), referenceDev.timeWindow)
            end
            
            % resolve frames-of-reference, ignoring delay of radial artery from carotid
            Dbolus = referenceDev.datetime0 + tReference - (arterialDev.datetime0 + tArterial);
            arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + referenceDev.datetime0 + ...
                                            tReference - ...
                                            tArterial - ...
                                            Dbolus;
                                        
            % manage failures of Dbolus
            if Dbolus > seconds(15)
                warning('mlpet:ValueError', ...
                    '%s.Dbolus was %g.\n', stackstr(), seconds(Dbolus))
                fprintf('scannerDev.datetime0 was %s.\n', datestr(referenceDev.datetime0))
                fprintf('tScanner was %g.\n', seconds(tReference))
                fprintf('arterialDev.datetime0 was %s.\n', datestr(arterialDev.datetime0))
                fprintf('tArterial was %g.\n', seconds(tArterial))
                Dbolus = seconds(15);
                arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + referenceDev.datetime0 + ...
                                                tReference - ...
                                                tArterial - ...
                                                Dbolus;
                fprintf('Dbolus forced -> %g\n', seconds(Dbolus))
                fprintf('arterialDev.datetimeMeasured forced -> %s\n', ...
                        datestr(arterialDev.datetimeMeasured))
            end
            if abs(Dbolus) > seconds(0.5*referenceDev.timeWindow) %%% UNRECOVERABLE
                error('mlpet:ValueError', ...
                    '%s.Dbolus was %g but scannerDev.timeWindow was %g.', ...
                    stackstr(), seconds(Dbolus), referenceDev.timeWindow)
                %Dbolus = seconds(0);
                %arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0;
                %warning('mlpet:ValueError', ...
                %        'BiographKit.alignArterialToScanner.Dbolus forced -> %g', seconds(Dbolus))
                %warning('mlpet:ValueError', ...
                %        'BiographKit.alignArterialToScanner.arterialDev.datetimeMeasured forced -> %s', ...
                %        datestr(arterialDev.datetimeMeasured))
            end
                                        
            % adjust arterialDev worldline to describe carotid bolus
            if opts.sameWorldline
                arterialDev.datetimeMeasured = arterialDev.datetimeMeasured + Dbolus;
            else
                arterialDev.shiftWorldlines(seconds(Dbolus));
            end
            arterialDev.Dt = seconds(Dbolus);
            arterialDatetimePeak = arterialDev.datetime0 + tArterial;
            
            % tBuffer
            ad.Ddatetime0 = seconds(referenceDev.datetime0 - arterialDev.datetime0);

            % synchronize decay correction times
            arterialDev.datetimeForDecayCorrection = referenceDev.datetimeForDecayCorrection;   
        end
        function [arterialDev,arterialDatetimePeak] = alignArterialToScanner(opts)
            %% ALIGNARTERIALTOSCANNER
            %  @param arterialDev is counting device or arterial sampling device, as mlpet.AbstractDevice.
            %  @param scannerlDev is mlpet.AbstractDevice.
            %  @param sameWorldline is logical.  Set true to avoid worldline shifts between arterial & scanner data.
            %  @return arterialDev, modified if not sameWorldline;
            %  @return arterialDatetimePeak, updated with alignments.
            %  @return arterialDev.Dt, always updated.
            %  @return updates mlaif.AifData.instance().
            
            arguments
                opts.arterialDev mlpet.InputFuncDevice
                opts.referenceDev mlpet.ScannerDevice
                opts.sameWorldline logical = false % enforce physical worldline
            end
            
            ad = mlaif.AifData.instance();
            arterialDev = copy(opts.arterialDev);
            scannerDev = opts.referenceDev;

            % find Dt of carotid bolus from radial-artery bolus, unresolved frames-of-reference
            unifTimes = 0:max(arterialDev.timeWindow, scannerDev.timesMid(end));
            artieralDevAD = arterialDev.activityDensity();
            arterialDevTimes = arterialDev.times(arterialDev.index0:arterialDev.indexF) - arterialDev.time0;
            arterialDevTimes = arterialDevTimes(1:length(artieralDevAD));
            arterialAct = interp1(arterialDevTimes, ...
                                 artieralDevAD, ...
                                 unifTimes);
            scannerAct = interp1(scannerDev.timesMid, ...
                                single(scannerDev.activityDensity('volumeAveraged', true)), ...
                                unifTimes);
            dscannerAct = movmean(diff(scannerAct), 9);
            if ~isempty(getenv('DEBUG'))
                figure; plot(unifTimes(1:end-1), diff(scannerAct));
                hold on
                plot(unifTimes(1:end-1), dscannerAct);
                hold off
                ylabel('activity density (Bq/mL)')
                title(stackstr())
            end

            thresh = 0.9; %arterialDev.threshOfPeak;
            [~,idxScanner] = max(dscannerAct > thresh*max(dscannerAct));
            [~,idxArterial] = max(arterialAct > thresh*max(arterialAct));
            tArterial = seconds(unifTimes(idxArterial));
            tScanner = seconds(unifTimes(idxScanner));
            
            % manage failures of interp1()
            if tArterial > seconds(0.5*scannerDev.timeWindow)
                warning('mlpet:ValueError', ...
                    '%s.tArterial was %g but arterialDev.timeWindow was %g.\n', ...
                    stackstr(), seconds(tArterial), arterialDev.timeWindow)
                ad.stableToInterpolation = false;
                [~,idxArterial] = max(arterialDev.activityDensity() > thresh*max(arterialDev.activityDensity()));
                tArterial = seconds(arterialDevTimes(idxArterial));
                fprintf('tArterial forced-> %g\n', seconds(tArterial))
            end            
            if tArterial > seconds(0.5*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlpet:ValueError', ...
                    '%s.tArterial was %g but arterialDev.timeWindow was %g.', ...
                    stackstr(), seconds(tArterial), arterialDev.timeWindow)
            end
            if tScanner > seconds(0.75*scannerDev.timeWindow)
                warning('mlpet:ValueError', ...
                    '%s.tScanner was %g but scannerDev.timeWindow was %g.\n', ...
                    stackstr(), seconds(tScanner), scannerDev.timeWindow)
                ad.stableToInterpolation = false;
                scannerDevAD = scannerDev.activityDensity('volumeAveraged', true, 'diff', true);
                [~,idxScanner] = max(scannerDevAD > thresh*max(scannerDevAD));
                tScanner = seconds(scannerDev.timesMid(idxScanner));
                fprintf('tScanner forced -> %g\n', seconds(tScanner))
            end
            if tScanner > seconds(0.75*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlpet:ValueError', ...
                    '%s.tScanner was %g but scannerDev.timeWindow was %g.', ...
                    stackstr(), seconds(tScanner), scannerDev.timeWindow)
            end
            
            % resolve frames-of-reference, ignoring delay of radial artery from carotid
            Dbolus = scannerDev.datetime0 + tScanner - (arterialDev.datetime0 + tArterial);
            arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0 + ...
                                            tScanner - ...
                                            tArterial - ...
                                            Dbolus;
                                        
            % manage failures of Dbolus
            if Dbolus > seconds(15)
                warning('mlpet:ValueError', ...
                    '%s.Dbolus was %g.\n', stackstr(), seconds(Dbolus))
                fprintf('scannerDev.datetime0 was %s.\n', datestr(scannerDev.datetime0))
                fprintf('tScanner was %g.\n', seconds(tScanner))
                fprintf('arterialDev.datetime0 was %s.\n', datestr(arterialDev.datetime0))
                fprintf('tArterial was %g.\n', seconds(tArterial))
                Dbolus = seconds(15);
                arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0 + ...
                                                tScanner - ...
                                                tArterial - ...
                                                Dbolus;
                fprintf('Dbolus forced -> %g\n', seconds(Dbolus))
                fprintf('arterialDev.datetimeMeasured forced -> %s\n', ...
                        datestr(arterialDev.datetimeMeasured))
            end
            if abs(Dbolus) > seconds(0.5*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlpet:ValueError', ...
                    '%s.Dbolus was %g but scannerDev.timeWindow was %g.', ...
                    stackstr(), seconds(Dbolus), scannerDev.timeWindow)
                %Dbolus = seconds(0);
                %arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0;
                %warning('mlpet:ValueError', ...
                %        'BiographKit.alignArterialToScanner.Dbolus forced -> %g', seconds(Dbolus))
                %warning('mlpet:ValueError', ...
                %        'BiographKit.alignArterialToScanner.arterialDev.datetimeMeasured forced -> %s', ...
                %        datestr(arterialDev.datetimeMeasured))
            end
                                        
            % adjust arterialDev worldline to describe carotid bolus
            if opts.sameWorldline
                arterialDev.datetimeMeasured = arterialDev.datetimeMeasured + Dbolus;
            else
                arterialDev.shiftWorldlines(seconds(Dbolus));
            end
            arterialDev.Dt = seconds(Dbolus);
            arterialDatetimePeak = arterialDev.datetime0 + tArterial;
            
            % tBuffer
            ad.Ddatetime0 = seconds(scannerDev.datetime0 - arterialDev.datetime0);

            % synchronize decay correction times
            arterialDev.datetimeForDecayCorrection = scannerDev.datetimeForDecayCorrection;            
        end
        function sesd = findCalibrationSession(varargin)
            sesd = mlsiemens.BiographDevice.findCalibrationSession(varargin{:});
        end
    end

    %% PROTECTED
    
    methods (Access = protected) 
        function this = InputFuncDevice(varargin)
 			this = this@mlpet.AbstractDevice(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
