classdef O15Builder < mlpet.PETBuilder
	%% O15Builder is a concrete builder for PET with [^15O] tracers; 
    %  builds maps of CBF, CBV, MTT, OEF, CMRO2 from activity-count maps of H[^15O] C[^15O] and O[^15O].   
    %
    %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
    %  with intravenous H2(15)O: I. theory and error analysis.
    %  J Nucl Med 1983;24:782?789
    %
    %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
    %  blood volume, blood flow, and oxygen utilization measured with
    %  O-15 radiotracers and positron emission tomography: revised metabolic
    %  computations. J Cereb Blood Flow Metab 1987;7:513?516
    %
    %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
    %  emission tomographic measurement of cerebral blood flow and
    %  permeability: surface area product of water using [15O] water and
    %  [11C] butanol. J Cereb Blood Flow Metab 1987;7:527?542
    %
    %  Version $Revision: 2610 $ was created $Date: 2013-09-07 19:15:00 -0500 (Sat, 07 Sep 2013) $ by $Author: jjlee $,  
 	%  last modified $LastChangedDate: 2013-09-07 19:15:00 -0500 (Sat, 07 Sep 2013) $ and checked into svn repository $URL: file:///Users/jjlee/Library/SVNRepository_2012sep1/mpackages/mlfsl/src/+mlfsl/trunk/O15Builder.m $ 
 	%  Developed on Matlab 7.13.0.564 (R2011b) 
 	%  $Id: O15Builder.m 2610 2013-09-08 00:15:00Z jjlee $ 
 	%  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad) 
    
    properties (Constant) 
        HDR_EXPRESSION   =  '(?<variable>[^=]+) = (?<value>[^=]+)';
        A_EXPRESSION     =  'A Coefficient \(Flow\)\s*=\s*(?<aflow>\d+\.?\d*E-?\d*)';
        B_EXPRESSION     =  'B Coefficient \(Flow\)\s*=\s*(?<bflow>\d+\.?\d*E-?\d*)';
        BLOOD_EXPRESSION =  'Blood Volume Factor\s*=\s*(?<bvfactor>\d+\.?\d*)';
        O2_EXPRESSION    =  'Total Oxygen Counts\s*=\s*(?<totaloxy>\d+\.?\d*E\+?\d*)';
        W_EXPRESSION     =  'PETT Conversion Factor\s*=\s*(?<factor>\d+\.?\d*\w+)';
        A_EXPRESSIONS    = {'A Coefficient \(Water\)\s*=\s*(?<coef>\d+\.?\d*E-?\d*)' ...
                            'B Coefficient \(Water\)\s*=\s*(?<coef>\d+\.?\d*E-?\d*)' ...
                            'A Coefficient \(Oxygen\)\s*=\s*(?<coef>\d+\.?\d*E-?\d*)' ...
                            'A Coefficient \(Oxygen\)\s*=\s*(?<coef>\d+\.?\d*E-?\d*)'};
        OXYGEN_CONTENT_EXPRESSION = ...
                            'Oxygen Content\s*=\s*(?<oxycont>\d+\.?\d*)';
        OC_PRERATIO      =  'oc_preratio';
        BUTANOL_CORRECTION = false;
        
        HO_MEANVOL_FILEPREFIX = 'ho_meanvol_default_161616fwhh';
        OC_FILEPREFIX         = 'oc_default';
        OO_MEANVOL_FILEPREFIX = 'oo_meanvol_default_161616fwhh';
        TR_FILEPREFIX         = 'tr_default';  
    end 

    properties (Dependent)
        tr
        hosum
        oc
        oosum                
        cbf
        cbv
        mtt
        oef
        cmro2
        tracers
        allPet
    end 

	methods % get/set 
        function obj  = get.tr(this) % lazy initialization
            if (isempty(this.tr_))
                this.tr_ = mlfourd.PETImagingComponent.load(this.converter.trFqFilename);
            end
            obj = this.tr_;
        end
        function obj  = get.hosum(this) 
            if (isempty(this.hosum_))
                this.hosum_ = mlfourd.PETImagingComponent.load(this.converter.hosumFqFilename);
            end
            obj = this.hosum_;
        end
        function obj  = get.oosum(this)
            if (isempty(this.oosum_))
                this.oosum_ = mlfourd.PETImagingComponent.load(this.converter.oosumFqFilename); 
            end
            obj = this.oosum_;
        end
        function obj  = get.oc(this)
            if (isempty(this.oc_))
                this.oc_ = mlfourd.PETImagingComponent.load(this.converter.ocFqFilename);
            end
            obj = this.oc_;
        end
        function obj  = get.cbf(this)
            if (isempty(this.cbf_))
                this.cbf_ = mlpet.O15Builder.count2cbf(this.hosum, this.hohdrFqFilename, this.BUTANOL_CORRECTION);
            end
            obj = this.cbf_;
        end
        function obj  = get.cbv(this)
            if (isempty(this.cbv_))
                this.cbv_ = mlpet.O15Builder.count2cbv(this.oc, this.ochdrFqFilename);
            end
            obj = this.cbv_;
        end
        function obj  = get.mtt(this)
            if (isempty(this.mtt_))
                assert(isa(this.cbf, 'mlfourd.ImagingComponent'));
                assert(isa(this.cbv, 'mlfourd.ImagingComponent'));
                this.mtt_ = this.cbv.safe_quotient(this.cbf, this.foreground, this.baseBlur, 60);
                this.mtt_.fileprefix = 'oc_ho_mtt';
            end
            obj = this.mtt_;
        end
        function obj  = get.oef(this)
            if (isempty(this.oef_))
                this.oef_ = mlpet.O15Builder.count2oef(this.oosum, this.oohdrFqFilename, this);
            end
            obj = this.oef_;
        end
        function obj  = get.cmro2(this)
            if (isempty(this.cmro2_))
                this.cmro2_ = mlpet.O15Builder.count2cmro2(this.oohdrFqFilename, this);
            end
            obj = this.cmro2_;
        end        
        function tr   = get.tracers(this)
            tr = this.converter.tracers;
        end
        function apet = get.allPet(this)
            assert(isa(this.allPet_, 'mlpatterns.ValueList'));
            assert(~isempty(this.allPet_));
            apet = this.allPet_; % expecting deep copy
        end
    end 
    
    methods (Static) 
        function this = createFromSessionPath(pth)
            assert(lexist(pth, 'dir'));
            this = mlpet.O15Builder( ...
                   mlfourd.PETConverter.createFromSessionPath(pth));
        end
        function this = createFromModalityPath(pth)
            assert(lexist(pth, 'dir'));
            this = mlpet.O15Builder( ...
                   mlfourd.PETConverter.createFromModalityPath(pth));
        end
        function this = createFromConverter(cvtr)
            assert(isa(cvtr, 'mlfourd.PETConverter'));d
            this = mlpet.O15Builder(cvtr);
        end
        
        function bldr = buildAll(      avging, petpth, varargin)
            import mlfsl.* mlpet.* mlfourd.*;
            assert(ischar(avging) || isa(avging, 'mlaveraging.AveragingStrategy'));
            assert(lexist(petpth, 'dir'));
            bldr = O15Builder.buildCounts(avging, petpth, varargin{:});
            bldr = bldr.buildPerfusion(   bldr); 
            bldr = bldr.buildOxygen(      bldr);
        end
        function bldr = buildCounts(   avging, petpth, refs)
            import mlfsl.* mlpet.* mlfourd.*;
            bldr = O15Builder(avging, petpth); 
            if (exist('refs','var')); bldr.references = refs; end
            bldr = bldr.coregisterAllCounts;
        end
        function bldr = buildPerfusion(bldr)
            bldr.cbf.save;
            bldr.cbv.save;
            bldr.mtt.save; 
        end
        function bldr = buildOxygen(   bldr)
            bldr.cmro2.save;
            bldr.oef.save;
        end
 
        function fwhh = petFwhh
            fwhh = min(mlpet.O15Builder.petPointSpread);
        end % static petFwhh
        function hwhh = petHwhh
            hwhh = mlpet.O15Builder.petFwhh / 2;
        end % static petHwhh
        function s    = petSigma
            s = fwhh2sigma(mlpet.O15Builder.petFwhh);
        end % static petHwhh        
    end
    
    methods
        function objs = perfuse(this, objs)
        end
        function objs = metabolize(this, objs)
        end            
        function this = resetCache(this)
            resetCache@mlfsl.FslBuilder(this);
            this.tr_    = [];
            this.hosum_ = [];
            this.oc_    = [];
            this.oosum_ = [];
            this.cbf_   = [];
            this.cbv_   = [];
            this.mtt_   = [];
            this.oef_   = [];
            this.cmro2_ = [];
        end 
        function this = O15Builder(varargin)
 			%% O15Builder 
 			%  Usage:  prefer using creation methods
           
            this = this@mlpet.PETBuilder(varargin{:});
        end % O15Builder (ctor)        
    end
        
    %% PRIVATE
    
    properties (Access = 'private')
        tr_    % all assigned by lazy initialization
        hosum_  
        oc_
        oosum_
        cbf_
        cbv_
        mtt_
        oef_
        cmro2_
    end % private properties

    methods (Static, Access = 'private')
        function cells         = obj2hdrCells(obj)
            import mlfourd.*;
            switch (class(obj))
                case 'cell'
                    cells = obj;
                case 'char'
                    assert(lexist(obj, 'file'));
                    cells = mlio.TextIO.textfileToCell(obj);
                otherwise
                    if (isa(obj, 'mlfourd.PETImagingComponent'))
                        cells = {};
                        for h = 1:length(obj.hdrFilenames)
                            oneHdr = mlpet.O15Builder.obj2hdrCells(obj.hdrFilenames{h});
                            cells  = [cells oneHdr]; %#ok<AGROW>
                        end
                    else
                        error('mlfsl:UnsupportedType', 'class(obj2hdr.obj)->%s', class(obj));
                    end
            end
        end % static obj2hdrCells
        function strct         = obj2hdrStruct(obj)
            import mlfsl.* mlpet.*;
            lines = O15Builder.obj2hdrCells(obj);
            strct = struct([]);
            for n = 1:length(lines) %#ok<FORFLG>
                names = regexp(lines{n}, O15Builder.HDR_EXPRESSION, 'names');
                dvals = str2double(names.value);
                if (~isnan(dvals)); names.values = dvals; end
                strct.(names.variable) = names.value; 
            end
        end % static obj2hdrStruct
        function cbf           = count2cbf(ho, hdr, butanolCorr)
            %% COUNT2CBF computes CBF in mL/min/100 g tissue
            %  Usage:  cbf = O15Builder.count2cbf(count, header[, butanol_correction])
            %                                     ^ PETImagingComponent
            %                                            ^ header object:  string, cells, ImagingComponent
            %                                                     ^ bool
            
            import mlfsl.* mlpet.* mlfourd.*;
            assert(isa(ho, 'mlfourd.ImagingComponent'));
            [AFlow, BFlow] = O15Builder.modelFlows(hdr);
             AFlow         = AFlow .* ones(size(ho)); % span the vector-space
             BFlow         = BFlow .* ones(size(ho));
             img           = ho.img .* (AFlow .* ho.img + BFlow);
             cbf           = ho.makeSimilar(img, 'from O15Builder.count2cbf', ...
                             O15Builder.cbfFileprefix(ho.fileprefix));
            if (~exist('butanolCorr', 'var'))
                butanolCorr = O15Builder.BUTANOL_CORRECTION; 
            end
            if (butanolCorr)
                cbf        = O15Builder.linkMexFlowButanol(cbf);
            end
        end % static count2cbf
        function cbv           = count2cbv(oc, hdr)
            %% COUNT2CBV computes CBV in mL/100 g tissue
            %  Usage:  cbv = O15Builder.count2cbv(count, header_object)
            %                                     ^ PETImagingComponent
            %                                            ^ header object:  string, cells, ImagingComponent
            
            import mlfsl.* mlpet.*;
            assert(isa(oc, 'mlfourd.ImagingComponent'));
            img = squeeze(O15Builder.modelBVFactor(hdr) .* oc.img);
            cbv = oc.makeSimilar(img, 'from O15Builder.count2cbv', ...
                  O15Builder.cbvFileprefix(oc.fileprefix));
        end % static count2cbv
        function oef           = count2oef(oo, hdr, bldr)
            %% COUNT2OEF
            %  Usage:  oef = O15Builder.count2oef(count, header_object, builder)
            %                                     ^ PETImagingComponent
            %                                            ^ header object:  string, cells, ImagingComponent
            %                                                           ^ O15Builder
            
            import mlfsl.* mlpet.*;
            assert(isa(oo, 'mlfourd.ImagingComponent'));
            
            f    = bldr.cbf.img;
            v    = bldr.cbv.img;
            R    = 0.85; % mean ratio of small-vessel to large-vessel Hct
            D    = 1.05; % density of brain, g/mL
            w    = modelW(hdr);
            a    = modelA(hdr);
            ICbv = squeeze(R .* (v .* D ./ 100) .* O15Builder.modelIntegralO2Counts(hdr));
            img  = scrubNaNs( ...
                  (w    .* oo.img - (a(1) .* f .* f + a(2) .* f) -          ICbv) ./ ...
                                   ((a(3) .* f .* f + a(4) .* f) - 0.835 .* ICbv), ...
                   true);
            img  = img .* bldr.foreground .* (img > 0) .* (img < 1);
            oef  = oo.makeSimilar(img, 'from O15Builder.count2oef', ...
                   O15Builder.oefFileprefix(oo.fileprefix));  
        end % static count2oef
        function cmro2         = count2cmro2(  hdr, bldr)
            %% COUNT2CMRO2
            %  Usage:  cmro2 = O15Builder.count2cmro2(header_object, builder)
            
            import mlfsl.* mlpet.*;
            f     = bldr.cbf.img;
            o     = bldr.oef.img; 
            img   = o .* f .* modelOxygenContent(hdr);
            cmro2 = bldr.oo.makeSimilar(img, 'from O15Builder.count2cmro2', ...
                    O15Builder.cmro2Fileprefix(bldr.oo.fileprefix, bldr.ho.fileprefix));
        end % static count2cmro2
        function [aflow,bflow] = modelFlows(hdrobj)
            %% MODELFLOWS
            %  Usage:  [aflow bflow] = modelFlows(header_object)
            %           ^     ^ values from ho1 headers
            %                                     ^ filename, cell-array, struct
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            % J Nucl Med 1983;24:782??789
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            % computations. J Cereb Blood Flow Metab 1987;7:513??516
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542
            
            import mlfsl.* mlpet.*;
            aflow    = NaN; bflow = NaN;
            hdrCells = O15Builder.obj2hdrCells(hdrobj);
            try
                for c = 1:length(hdrCells) %#ok<FORFLG>
                    paramLine = hdrCells{c};
                    if (~isempty(strfind(paramLine, 'A Coef')))
                        names = regexpi(paramLine, O15Builder.A_EXPRESSION, 'names'); 
                        aflow = str2double(names.aflow); 
                    end
                    if (~isempty(strfind(paramLine, 'B Coef')))
                        names = regexpi(paramLine, O15Builder.B_EXPRESSION, 'names');
                        bflow = str2double(names.bflow); 
                    end
                end 
            catch ME
                warning('mfiles:MissingParameter', 'modelFlows aflow->%d bflow->%d', aflow, bflow);
                handexcept(ME);
            end
        end % static modelFLows        
        function oxy           = modelBVFactor(hdrobj)
            %% MODELBVFACTOR
            %  Usage:  oxy = modelBVFactor(header_ojbect)
            %          ^     oxygen content from oo headers
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            % J Nucl Med 1983;24:782??789
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            % computations. J Cereb Blood Flow Metab 1987;7:513??516
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542
            
            import mlfsl.* mlpet.*;
            oxy      = NaN;
            hdrCells = O15Builder.obj2hdrCells(hdrobj);
            try
                for c = 1:length(hdrCells) %#ok<FORFLG>
                    if (~isempty(strfind(hdrCells{c}, 'Blood Volume Factor')))
                        names = regexpi(hdrCells{c}, O15Builder.BLOOD_EXPRESSION, 'names');
                        oxy   = str2double(names.bvfactor); 
                    end
                end
            catch ME
                handexcept(ME);
            end
        end % static modelBVFactor
        function int           = modelIntegralO2Counts(hdrobj)
            %% MODELINTEGRALO2COUNTS
            %  Usage:  integral = modelIntegralO2Counts(header_object)
            %          ^          total oxygen counts from oo1 hdr files
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542
            
            import mlfsl.* mlpet.*;
            int      = NaN;
            hdrCells = O15Builder.obj2hdrCells(hdrobj);            
            try
                for j = 1:length(hdrCells) %#ok<FORFLG>
                    paramLine = hdrCells{j};
                    if (strcmp('Total', paramLine(2:6)))
                        names = regexpi(paramLine, O15Builder.O2_EXPRESSION, 'names');
                        int   = str2double(names.totaloxy); 
                    end
                end
            catch ME
                handexcept(ME);
            end
        end % static modelInteralO2Counts
        function w             = modelW(hdrobj)
            %% MODELW
            %  Usage:  w = modelW(header_object)
            %          ^   factor to convert PET counts/pixel to well counts/mL (PETT Conversion Factor)
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542
            
            import mlfsl.* mlpet.*;
            w        = NaN;
            hdrCells = O15Builder.obj2hdrCells(hdrobj); 
            try
                for j = 1:length(hdrCells) %#ok<FORFLG>
                    paramLine = hdrCells{j};
                    if (strcmp('PETT', paramLine(2:5)))
                        names = regexpi(paramLine, O15Builder.W_EXPRESSION, 'names');
                        w     = str2double(names.factor); 
                        break;
                    end
                end
            catch ME
                handexcept(ME);
            end
        end % static modelW
        function a             = modelA(hdrobj)
            %% MODELA
            %  Usage:  a = modelA(header_object)
            %          ^    [a1 a2 a3 a4] constants in quadratic equations
            %                a1 from water A
            %                   a2 from water B
            %                      a3 from O2 A
            %                         a4 from O2 B
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542
            
            import mlfsl.* mlpet.*;
            a        = NaN;
            hdrCells = O15Builder.obj2hdrCells(hdrobj); 
            try
                for j = 1:length(hdrCells) %#ok<FORFLG>
                    if (~isempty(strfind(hdrCells{j}, 'Coefficient')))
                        for k = 1:length(O15Builder.A_EXPRESSIONS)
                            names = regexpi(hdrCells{j}, O15Builder.W_EXPRESSION{k}, 'names');
                            if (~isempty(names))
                                a(k)  = str2double(names.coef); 
                                break
                            end
                        end
                    end
                end
            catch ME
                handexcept(ME);
            end
        end % static modelA
        function oxy           = modelOxygenContent(hdrobj)
            %% MODELOXYGENCONTENT
            % Usage:  oxy = modelOxygenContent(header_object)
            %         ^     oxygen content from oo1 hdr files
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542

            import mlfsl.* mlpet.*;
            oxy      = NaN;
            hdrCells = O15Builder.obj2hdrCells(hdrobj); 
            try
                for j = 1:length(hdrCells) %#ok<FORFLG>
                    hline = hdrCells{j};
                    if (strcmp('Oxygen C', hline(2:9)))
                        names = regexpi(hline, O15Builder.OXYGEN_CONTENT_EXPRESSION, 'names');
                        oxy = str2double(names.oxycont); 
                    end
                end
            catch ME
                handexcept(ME);
            end
        end % static modelOxygenContent
        function fp            = cbfFileprefix(fp)
            fp = fileprefix(fp, mlfourd.NIfTId.FILETYPE_EXT);
            fp = [fp '_cbf'];
        end % static cbfFileprefix   
        function fp            = cbvFileprefix(fp)
            fp = fileprefix(fp, mlfourd.NIfTId.FILETYPE_EXT);
            fp = [fp '_cbv'];
        end % static cbvFileprefix
        function fp            = oefFileprefix(fp)
            fp = fileprefix(fp, mlfourd.NIfTId.FILETYPE_EXT);
            fp = [fp '_oef'];
        end % static oefFileprefix
        function fp            = cmro2Fileprefix(fp, fp2)
            fp  = fileprefix(fp,  mlfourd.NIfTId.FILETYPE_EXT);
            fp2 = fileprefix(fp2, mlfourd.NIfTId.FILETYPE_EXT);
            fp = [fp '_' fp2 '_cmro2'];
        end % static oefFileprefix
        function pic           = linkMexFlowButanol(pic)
            pic = pic.makeSimilar(linkMexFlowButanol(pic.img), 'O15Builder.linkMexFlowButanol', pic.fileprefix);
        end % static linkMexFlowButanol
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

