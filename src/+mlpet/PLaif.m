classdef PLaif < handle
	%% PLAIF   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$     
    
    properties (Constant)        
        LAMBDA           = 0.95        % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        LAMBDA_DECAY_15O = 0.005670379 % k | dq/dt = -kq, for activity q of [15O] with half-life = 122.24 s
    end
    
    methods (Static)
        function conc = bolusFlowFractal(a, b, p, t0, t)
            if (t(1) >= t0) % saves extra flops from slide()
                t_   = t - t0;
                conc = t_.^a .* exp(-(b*t_).^p);
            else
                t_   = t - t(1);
                conc = t_.^a .* exp(-(b*t_).^p);
                conc = mlpet.PLaif.slide(conc, t, t0 - t(1));
            end
            conc = conc*p*b^(a+1)/gamma((a+1)/p);
            conc = abs(conc);
        end
        function conc = bolusFlowTerm(a, b, t0, t)
            if (t(1) >= t0)
                t_   = t - t0;
                conc = t_.^a .* exp(-b*t_);
            else 
                t_   = t - t(1);
                conc = t_.^a .* exp(-b*t_);
                conc = mlpet.PLaif.slide(conc, t, t0 - t(1));
            end
            conc = conc*b^(a+1)/gamma(a+1);
            conc = abs(conc);
        end
        function conc = bolusSteadyStateTerm(e, g, t0, t)
            import mlpet.*;
            if (t(1) >= t0)
                t_   = t - t0;
                conc = e * (1 - exp(-g*t_));
            else 
                t_   = t - t(1);
                conc = e * (1 - exp(-g*t_));
                conc = PLaif.slide(conc, t, t0 - t(1));
            end
        end
        function conc = flowFractal(a, b, d, ldecay, p, t0, t)
            dt = (t(2) - t(1))/2;
            t_ = t(1):dt:t(end);
            import mlpet.*;
            expl = exp(-ldecay*(t_ - t0)) .* PLaif.Heaviside(t_, t0);
            expd = exp(-d*(t_));
            conc = conv(PLaif.bolusFlowFractal(a, b, p, t0, t_) .* expl, expd);
            conc = conc(1:length(t_));
            conc = pchip(t_, conc, t); 
        end
        function conc = flowTerm(a, b, d, t0, t)
            %% FLOWTERM quickly evaluates convolutions expressible as:
            %  \Gamma(\alpha+1, \beta) \ast \text{exp}(-\Delta (t - t_0)).
           
            if (t(1) >= t0)
                t_   = t - t0;
                conc = exp(-d*t_) * b^(a+1) / (b-d)^(a+1);
                conc = conc .* gammainc((b - d)*t_, a+1);
            else 
                t_   = t - t(1); 
                conc = exp(-d*t_) * b^(a+1) / (b-d)^(a+1);
                conc = conc .* gammainc((b - d)*t_, a+1);
                conc = mlpet.PLaif.slide(conc, t, t0 - t(1));
            end
            conc = abs(conc);
        end
        function conc = steadyStateTerm(d, e, g, ldecay, t0, t)
            if (t(1) >= t0)
                t_   = t - t0;            
                conc = e * ((exp(-(ldecay + g)*t_) - exp(-d*t_))/(ldecay + g - d) - ...
                            (exp( -ldecay*t_)      - exp(-d*t_))/(ldecay - d));
            else  
                t_   = t - t(1);
                conc = e * ((exp(-(ldecay + g)*t_) - exp(-d*t_))/(ldecay + g - d) - ...
                            (exp( -ldecay*t_)      - exp(-d*t_))/(ldecay - d));
                conc = mlpet.PLaif.slide(conc, t, t0 - t(1));
            end
            conc = abs(conc);
        end
        
        function [vec,T] = ensureRow(vec)
            if (~isrow(vec))
                vec = vec';
                T = true;
                return
            end
            T = false; 
        end
        function [S0,t0] = estimateS0t0(indDat, depDat)
            searchFraction = 0.05;
            bigChange = searchFraction * (max(depDat) - min(depDat));
            for ti = 1:length(indDat)-1
                if (depDat(ti+1) - depDat(ti) > bigChange)
                    tilast = ti;
                    break
                end
            end
            S0 = max(depDat);
            t0 = indDat(tilast);
        end
        function h       = Heaviside(t, t0)
            h = zeros(size(t));
            h = h + double(t > t0);
        end
        function f       = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
        end
        function A       = pchip(t, A, t_, Dt)
            %% PCHIP slides discretized function A(t) to A(t_ - Dt);
            %  Dt > 0 will slide conc(t) towards to later values of t.
            %  Dt < 0 will slide conc(t) towards to earlier values of t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            %  @param t  is the initial t sampling
            %  @param A  is the initial A sampling
            %  @param t_ is the final   t sampling
            %  @param Dt is the shift of t_
            
            tspan = t(end) - t(1);
            dt    = t(2) - t(1);
            t     = [(t - tspan - dt) t]; % prepend times
            A     = [zeros(size(A)) A]; % prepend zeros
            A     = pchip(t, A, t_ - Dt); % interpolate onto t shifted by Dt; Dt > 0 shifts conc to right
        end
        function conc    = slide(conc, t, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t - Dt);
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            
            import mlpet.*;
            [conc,trans] = PLaif.ensureRow(conc);
            t            = PLaif.ensureRow(t);
            
            tspan = t(end) - t(1);
            tinc  = t(2) - t(1);
            t_    = [(t - tspan - tinc) t];   % prepend times
            conc_ = [zeros(size(conc)) conc]; % prepend zeros
            conc_(isnan(conc_)) = 0;
            conc  = pchip(t_, conc_, t - Dt); % interpolate onto t shifted by Dt; Dt > 0 shifts to right
            
            if (trans)
                conc = conc';
            end
        end
        function tf      = uniformSampling(t)
            t   = mlsystem.VectorTools.ensureRowVector(t);
            dts = t(2:end) - t(1:end-1);
            dt1 = t(2) - t(1);
            tf  = all(abs(dt1*ones(1,length(dts)) - dts) < eps('single'));
        end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

