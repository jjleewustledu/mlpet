classdef (Abstract) ISessionTracerData 
	%% ISESSIONTRACERDATA  

	%  $Revision$
 	%  was created 27-May-2018 16:51:10 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)
        attenuationCorrected 
        attenuationTag
        convertedTag
        doseAdminDatetimeTag
        frameTag
        pnumber
        rawdataDir
        snumber
        supScanList
        tauIndices % use to select frames:  this.taus := this.taus(this.tauIndices)
        taus
        times % depends on taus
        timeMidpoints % depends on taus
        tracer		
        tracerBlurArg
        umapBlurArg        
 	end

	methods (Abstract)
        absScatterCorrected(this)
        agi(this)
        arterialSamplerCalCrv(this)
        arterialSamplerCrv(this)
        cbf(this)
        cbv(this)
        CCIRRadMeasurements(this)
        cmrglc(this)
        cmro2(this)
        ct(this)
        ctMask(this)
        ctMasked(this)
        ctRescaled(this)
        fdg(this)
        gluc(this)
        ho(this)
        isotope(this)
        oc(this)
        oef(this)
        ogi(this)
        oo(this)
        petLocation(this)
        petObject(this)
        petPointSpread(this)
        tracerConvertedLocation(this)
        tracerListmodeFrameV(this)   
        tracerListmodeLocation(this)
        tracerListmodeMhdr(this)
        tracerListmodeSif(this)    
        tracerListmodeUmap(this)
        tracerLocation(this)
        tracerPristine(this)
        tracerRawdataLocation(this)
        tracerResolved(this)
        tracerResolvedFinal(this)
        tracerRevision(this)        
        tracerSif(this)
        tracerSuvr(this)
        tracerSuvrNamed(this) % KLUDGE
        umap(this)
        umapSynth(this)
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

