classdef Rois 
	%% ROIS is a lightweight creation class for use by mlpet and related packages.

	%  $Revision$
 	%  was created 08-Apr-2020 19:17:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties
        excludeLarge
        voxelTime % from this.registry_
        wallClockLimit % from this.registry_
    end
    
	properties (Dependent)
        mriPath
 		roisPath
        voxelLimit
    end
    
    methods (Static)
        function this = createFromSession(sesd)
            this = mlpet.Rois('sessionData', sesd);
        end
        function largeNVoxels(wm, indices, cpuh)
            %  @param wm is ImagingFormatContext or filename.
            %  @param indices is numeric vector.
            %  @param cpuh is scalar.
            
            if ~isa(wm, 'mlfourd.ImagingFormatContext')
                wm = mlfourd.ImagingFormatContext(wm);
            end
            
            for i = indices
                Nvxl = dipsum(wm.img == i);
                if Nvxl > cpuh*3600/20
                    fprintf('i->%g has %g voxels\n', i, Nvxl)
                end
            end
        end
    end
    
    methods
        
        %% GET
        
        function g = get.mriPath(this)
            g = fullfile(this.sessionData_.sessionPath, 'mri', '');
        end
        function g = get.roisPath(this)
            g = fullfile(this.sessionData_.subjectPath, 'resampling_restricted', '');
        end
        function g = get.voxelLimit(this)
            g = this.wallClockLimit/this.voxelTime;
        end
        
        %%
        
        function [set,ifc] = constructBrainSet(this)
            existingSet = this.constructExistingSet();
            brain = mlfourd.ImagingContext2(fullfile(this.roisPath, 'brain.4dfp.hdr'));
            brain = brain.blurred(1);
            brain = brain.binarized();
            brain = brain & ~existingSet{1};
            brain.fileprefix = 'mlpet.Rois_constructBrainSet_brain';
            brain.save
            set = {brain};
            ifc = brain.fourdfp;
        end
        function [set,ifc] = constructDesikanSet(this, varargin)
            set = {};
            ifc = mlfourd.ImagingFormatContext(fullfile(this.mriPath, 'aparc+aseg.mgz'));
            ifc.filesuffix = '.4dfp.hdr';
            indices = [2:85 251:255 1000:1035 2000:2035];
            for i = indices
                ifc1 = copy(ifc);
                ifc1.img = ifc.img == i;
                if ~this.maskIsempty(ifc1)
                    ifc1.fileprefix = sprintf('%s%i', ifc.fileprefix, i);
                    set = [set {mlfourd.ImagingContext2(ifc1)}]; %#ok<AGROW>
                end
            end
        end
        function [set,ifc] = constructDestrieuxSet(this, varargin)
            set = {};
            ifc = mlfourd.ImagingFormatContext(fullfile(this.mriPath, 'aparc.a2009s+aseg.mgz'));
            ifc.filesuffix = '.4dfp.hdr';
            indices = [2:85 251:255 1000 2000 11101:11175 12101:12175];
            for i = indices
                ifc1 = copy(ifc);
                ifc1.img = ifc.img == i;
                if ~this.maskIsempty(ifc1)
                    ifc1.fileprefix = sprintf('%s%i', ifc.fileprefix, i);
                    set = [set {mlfourd.ImagingContext2(ifc1)}]; %#ok<AGROW>
                end
            end
        end        
        function [set,existing] = constructExistingSet(this)
            %  @returns {mlfourd.ImagingContext2() with existing ks}, possibly all false
            %  @returns mlfourd.ImagingFormatContextf()
            
            pwd0 = pushd(this.roisPath);            
            existing = mlfourd.ImagingFormatContext('T1001.4dfp.hdr');
            assert(~isempty(existing))
            existing.img = zeros(size(existing));
            for g = globT('ks*parc*_on_T1001*.4dfp.hdr') % maps of computed ks
                ifc = mlfourd.ImagingFormatContext(g{1});
                existing.img = existing.img + ifc.img;
            end
            existing.img = sum(existing.img, 4); % contract over ks
            existing.img = existing.img > 0;
            existing.fileprefix = 'mlpet_Rois_constructExistingSet_existing';
            existing.save
            set = {mlfourd.ImagingContext2(existing)}; 
            popd(pwd0)            
        end
        function [set,parc] = constructWmSet(this, varargin)
            set = {};            
            parc = mlfourd.ImagingFormatContext(fullfile(this.roisPath, 'wmparc.4dfp.hdr'));
            indices = [2:85 251:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002];
            indices = this.selectedIndices(indices, parc, varargin{:}); % selects reasonable voxels
            for i = indices
                parci = copy(parc);
                parci.img = parc.img == i;
                if ~this.maskIsempty(parci)
                    parci.fileprefix = sprintf('%s%i', parc.fileprefix, i);
                    set = [set {mlfourd.ImagingContext2(parci)}]; %#ok<AGROW>
                end
            end
        end
        function tf = maskIsempty(~, m)
            assert(isa(m, 'mlfourd.ImagingFormatContext'))
            tf = 0 == dipsum(m.img);
        end
        function ind = selectedIndices(this, indices, parcs, varargin)
            %% select indices for load balancing; skip indices with no voxels and indices with too many voxels
            %  @param indices, numeric, are FreeSurfer parc/seg indices.
            %  @param parcs, mlfourd.ImagingFormatContext contains FreeSurfer parc/seg.
            %  @param cpuIndex, integer.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'indices', @isnumeric)
            addRequired(ip, 'parcs', @(x) isa(x, 'mlfourd.ImagingFormatContext') && ~isempty(x))
            addParameter(ip, 'cpuIndex', [], @(x) isnumeric(x) && ~isempty(x))
            parse(ip, indices, parcs, varargin{:})
            ipr = ip.Results;
            
            matfile = sprintf('%s_selectedIndices.mat', ipr.parcs.fqfileprefix);
            if isfile(matfile)
                loaded = load(matfile);
                ind = loaded.cpu2selectedIndices(ipr.cpuIndex);
                return
            end
            
            surferIndices2Nvoxels = containers.Map(indices, zeros(size(indices)));
            cpu2selectedIndices = containers.Map('KeyType', 'uint32', 'ValueType', 'any'); % cpuIndex -> indices array
            
            % collect surferIndices2Nvoxels
            for i = indices
                surferIndices2Nvoxels(i) = dipsum(parcs.img == i);
            end
            tbl = table(cell2mat(surferIndices2Nvoxels.keys)', ...
                cell2mat(surferIndices2Nvoxels.values)', ...
                zeros(size(surferIndices2Nvoxels.values')), ...
                'VariableNames', {'surferIndex' 'Nvoxels' 'cpuIndex'}, ...
                'RowNames', cellfun(@num2str, ascol(surferIndices2Nvoxels.keys), 'UniformOutput', false));            
            tbl = tbl(0 < tbl.Nvoxels & tbl.Nvoxels < this.voxelLimit, :);
            tbl = sortrows(tbl, 'Nvoxels', 'descend');
            
            % construct cpu2selectedIndices            
            c = 1;
            for r = 1:size(tbl, 1)
                tbl1 = tbl(tbl.cpuIndex == 0, :);
                if isempty(tbl1); break; end
                voxelRoom = this.voxelLimit;
                cpu2selectedIndices(c) = [];
                while 0 < voxelRoom && ~isempty(tbl1)
                    surferIndex = tbl1{1, 'surferIndex'}; % from sorted tbl1
                    cpu2selectedIndices(c) = [cpu2selectedIndices(c) surferIndex];
                    tbl{num2str(surferIndex), 'cpuIndex'} = c;              
                    voxelRoom = voxelRoom - tbl1{1, 'Nvoxels'};                
                    tbl1 = tbl(tbl.Nvoxels < voxelRoom & tbl.cpuIndex == 0, :); % still sorted           
                end                
                c = c + 1;
            end
            
            % save
            save(matfile, 'cpu2selectedIndices', 'surferIndices2Nvoxels', 'tbl')            
            ind = cpu2selectedIndices(ipr.cpuIndex);
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
        registry_
    end

	methods (Access = protected)		  
 		function this = Rois(varargin)
 			%% ROIS
 			%  @param .

            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'excludeLarge', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
 			this.sessionData_ = ipr.sessionData;
            this.excludeLarge = ipr.excludeLarge;
            
            this.registry_ = mlraichle.StudyRegistry.instance();
            this.voxelTime = this.registry_.voxelTime;
            this.wallClockLimit = this.registry_.wallClockLimit;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

