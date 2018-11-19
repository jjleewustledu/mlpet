classdef Resources < handle
    
    properties (Dependent)
        alpha
        defaultN
        ignoreFinishfile
        matlabDrive
        neverMarkFinished
        noiseFloorOfActivity % Bq/mL
        pointSpread % mm
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
        function g = get.ignoreFinishfile(this)
            g = this.ignoreFinishfile_;
        end
        function g = get.matlabDrive(~)
            g = fullfile(getenv('HOME'), 'MATLAB-Drive', '');
        end
        function g = get.neverMarkFinished(this)
            g = this.neverMarkFinished_;
        end
        function g = get.noiseFloorOfActivity(~)
            g = 0; % Bq/mL
        end
        function g = get.pointSpread(~)
            g = mlsiemens.MMRRegistry.instance.petPointSpread;
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
        ignoreFinishfile_        
        neverMarkFinished_
    end
    
    methods (Access = private)
        function this = Resources()
            this.alpha_ = 0.05;
            this.data_  = [];
            this.defaultN_ = true;
            
            this.ignoreFinishfile_ = false;
            this.neverMarkFinished_ = false;
        end
    end
   
end
