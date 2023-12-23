classdef IdifDevice < handle & mlpet.InputFuncDevice
    %% is an adaptor design pattern, intended for wrapping mlpet.ScannerDevice.
    %  
    %  Created 16-Dec-2023 22:24:31 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
	properties (Dependent)
        background
        baselineActivity
        baselineActivityDensity
        baselineCountRate
 		calibrationAvailable
        catheterKit
        deconvCatheter
        do_close_fig
        Dt
        hct
        invEfficiency
        isWholeBlood
        radialArteryKit
        t0_forced
        visibleVolume
    end

	methods % GET/SET        
        function g = get.background(this)
            try
                g = this.inner_device_.background;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.baselineActivity(this)
            try
                g = this.inner_device_.baselineActivity;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.baselineActivityDensity(this)
            try
                g = this.inner_device_.baselineActivityDensity;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.baselineCountRate(this)
            try
                g = this.inner_device_.baselineCountRate;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.calibrationAvailable(this)
            g = this.inner_device_.calibrationAvailable;
        end
        function g = get.catheterKit(this)
            g = this.inner_device_.catheterKit;
        end
        function g = get.deconvCatheter(this)
            g = this.inner_device_.deconvCatheter;
        end
        function     set.deconvCatheter(this, s)
            this.inner_device_.deconvCatheter = s;
        end
        function g = get.do_close_fig(this)
            g = this.inner_device_.do_close_fig;
        end
        function     set.do_close_fig(this, s)
            try
                this.inner_device_.do_close_fig = s;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.Dt(this)
            g = this.inner_device_.Dt;
        end
        function     set.Dt(this, s)
            this.inner_device_.Dt = s;
        end
        function g = get.hct(this)
            try
                g = this.inner_device_.hct;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.invEfficiency(this)
            g = this.inner_device_.invEfficiency;
        end
        function g = get.isWholeBlood(this)
            g = this.inner_device_.isWholeBlood;
        end
        function g = get.radialArteryKit(this)
            try
                g = this.inner_device_.radialArteryKit;
            catch ME
                handexcept(ME)
            end
        end
        function g = get.t0_forced(this)
            g = this.inner_device_.t0_forced;
        end
        function     set.t0_forced(this, s)
            this.inner_device_.t0_forced = s;
        end
        function g = get.visibleVolume(this)
            g = this.inner_device_.data_.visibleVolume;
        end
    end

    methods 
        function a = activity(this, varargin)
            error("mlpet:NotImplemented", stackstr())
        end
        function a = activityDensity(this, varargin)
            error("mlpet:NotImplemented", stackstr())
        end
        function a = appendActivityDensity(this, varargin)
            a = this.inner_device_.appendActivityDensity(varargin{:});
        end
        function [a1,t1] = activityDensityInterp1(this, varargin)
            try
                [a1,t1] = this.inner_device_.activityDensityInterp1(varargin{:});
            catch ME
                handexcept(ME)
            end
        end
        function that = blurred(this, varargin)
            try
                that = this.inner_device_.blurred(varargin{:});
            catch ME
                handexcept(ME)
            end
        end
        function c = countRate(this, varargin)
            error("mlpet:NotImplemented", stackstr())
        end
        function that = masked(this, varargin)
            try
                that = this.inner_device_.masked(varargin{:});
            catch ME
                handexcept(ME)
            end
        end
        function h = plot(this, varargin)
            try
                h = this.inner_device_.plot(varargin{:});
            catch ME
                handexcept(ME)
            end
        end
        function that = timeAveraged(this, varargin)
            try
                that = this.inner_device_.timeAveraged(varargin{:});
            catch ME
                handexcept(ME)
            end
        end
        function that = volumeAveraged(this, varargin)
            try
                that = this.inner_device_.volumeAveraged(varargin{:});
            catch ME
                handexcept(ME)
            end
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlpet.IdifDevice(varargin{:});
        end
    end

    %% PROTECTED

    methods (Access = protected)
        function this = IdifDevice(varargin)
            this = this@mlpet.InputFuncDevice(varargin{:});
        end
    end

    %% PRIVATE

    properties (Access = private)
        inner_device_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
