classdef Resources < handle
    
    properties (Dependent)
        alpha
        defaultN
        ignoreFinishMark
        matlabDrive
        neverMarkFinished
        nipetFolder
        noiseFloorOfActivity % Bq/mL
        pointSpread % mm
        reconstructionVersion
        suffixBlurPointSpread
    end
    
    methods (Static)
        function this = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlpet.Resources();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end
    
    methods
        
        %% GET
        
        function g = get.alpha(this)
            g = this.alpha_;
        end
        function set.alpha(this, s)
            assert(isnumeric(s) && eps < s && s < 1);
            this.alpha_ = s;
        end
        function g = get.defaultN(this)
            g = this.defaultN_;
        end
        function set.defaultN(this, s)
            assert(islogical(s));
            this.defaultN_ = s;
        end
        function g = get.ignoreFinishMark(this)
            g = this.ignoreFinishMark_;
        end
        function g = get.matlabDrive(~)
            g = fullfile(getenv('HOME'), 'MATLAB-Drive', '');
        end
        function g = get.neverMarkFinished(this)
            g = this.neverMarkFinished_;
        end
        function g = get.nipetFolder(~)
            g = this.nipetFolder_;
        end
        function g = get.noiseFloorOfActivity(~)
            g = 0; % Bq/mL
        end
        function g = get.pointSpread(~)
            g = mlsiemens.MMRRegistry.instance.petPointSpread;
        end
        function g = get.reconstructionVersion(this)
            if (lstrfind(getenv('SUBJECTS_DIR'), this.nipetFolder))
                g = sprintf('nipet=1.1');
                return
            end
            g = sprintf('Siemens e7 E11p');
        end
        function g = get.suffixBlurPointSpread(this)
            g = ['_b' num2str(floor(10*this.pointSpread))];
        end
        
        %%
        
        function datademo(this, val)
            this.data_ = val;
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        alpha_
        data_
        defaultN_  
        ignoreFinishMark_        
        neverMarkFinished_
        nipetFolder_
        nipetVersion_ = 1.1
    end
    
    methods (Access = private)
        function this = Resources()
            this.alpha_ = 0.05;
            this.data_  = [];
            this.defaultN_ = true;            
            this.ignoreFinishMark_ = false;
            this.neverMarkFinished_ = false;
            this.nipetFolder_ = 'Pawel';
        end
    end
   
end
