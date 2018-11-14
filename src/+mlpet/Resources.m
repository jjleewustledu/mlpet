classdef Resources < handle
    
    properties (Dependent)
        alpha
        matlabDrive
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
        function g = get.matlabDrive(this)
            g = fullfile(getenv('HOME'), 'MATLAB-Drive', '');
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
    end
    
    methods (Access = private)
        function this = Resources()
            this.alpha_ = 0.05;
            this.data_  = [];
        end
    end
   
end
