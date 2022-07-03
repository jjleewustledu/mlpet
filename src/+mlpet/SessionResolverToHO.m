classdef SessionResolverToHO < handle & mlpet.SessionResolverToTracer
	%% SESSIONRESOLVERTOHO  

	%  $Revision$
 	%  was created 08-Jan-2020 22:26:43 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	    
	methods        
        function this = alignCrossModal(this)
            %% ALIGNCROSSMODAL
            %  theFdg,theHo,theOo,theOc
            %  @return t4 in this.t4s:            e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_to_op_fdgv1r1_t4}.
            %  @return resolved in this.product:  e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_op_fdgv1r1.4dfp.hdr}.            

            pwd0     = pushd(this.workpath);   
            
            theOo    = copy(this.alignCommonModal('OO'));
                       theOo.productAverage('OO');            
            theOc    = copy(this.alignCommonModal('OC'));
                       theOc.productAverage('OC');            
            theHo    = copy(this.alignCommonModal('HO'));
                       theHo.productAverage('HO');
            prefixes = { theHo.product{1}.fileprefix ...
                         theOo.product{1}.fileprefix ...
                         theOc.product{1}.fileprefix };
            
            this = copy(theHo);  
            pwd1 = pushd(this.product{1}.filepath);
            this.resolve(prefixes, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'Msktgen', ...
                'client', 'alignCrossModal_this');
            popd(pwd1);
            
            that = copy(this);
            that.alignDynamicImages('commonRef', theOo, 'crossRef', this);
            that.alignDynamicImages('commonRef', theOc, 'crossRef', this);
            that.alignDynamicImages('commonRef', theHo, 'crossRef', this);
            
            popd(pwd0);
            this.packageProduct(that.product);
        end
        function tf   = isfinished(this)
            tf = false;
            return
            
            import mlsystem.DirTool
            pwd0 = pushd(fullfile(this.sessionData.subjectPath, ''));
            dt_ho  = DirTool('ho*_op_ho*_on_op_ho_avgr1.4dfp.img');
            dt_oo  = DirTool('oo*_op_oo*_on_op_ho_avgr1.4dfp.img');
            dt_oo  = DirTool('oc*_op_oc*_on_op_ho_avgr1.4dfp.img');
            popd(pwd0)
            
            tf = ~isempty(dt_ho.fqfns) && ...
                 ~isempty(dt_oo.fqfns) && ...
                 ~isempty(dt_oc.fqfns);
        end
        function t4_obj = t4_mul(this)
            
            fv = mlfourdfp.FourdfpVisitor;
            pwd0 = pushd(this.workpath);
            ref = lower(this.client_.sessionData.referenceTracer);
            
            %% HO
            
            t4_obj.ho = {};
            ho_glob = this.hoglob(); %('hodt[0-9]+_avgtr1_to_op_hodt[0-9]+r1_t4');
            ho_to_op_ref_t4 = sprintf('ho_avgr1_to_op_%s_avgr1_t4', ref);
            for h = asrow(ho_glob)
                t4 = sprintf('%s_to_op_%s_avgr1_t4',  this.collectionRB.frontOfT4(h{1}), ref);
                mlbash(sprintf('t4_mul %s %s %s', h{1}, ho_to_op_ref_t4, t4))
                t4_obj.ho = [t4_obj.ho t4];
            end
            if isempty(t4_obj.ho)
                if ~isfile(sprintf('ho_avgr1_to_op_%s_avgr1_t4', ref))
                    fv.t4_ident(sprintf('ho_avgr1_to_op_%s_avgr1_t4', ref))
                end
                t4_obj.ho = {sprintf('ho_avgr1_to_op_%s_avgr1_t4', ref)};
            end
            
            %% OO
            
            t4_obj.oo = {};
            oo_glob = this.ooglob();
            oo_to_op_ref_t4 = sprintf('oo_avgr1_to_op_%s_avgr1_t4', ref);
            for o = asrow(oo_glob)
                t4 = sprintf('%s_to_op_%s_avgr1_t4', this.collectionRB.frontOfT4(o{1}), ref);
                mlbash(sprintf('t4_mul %s %s %s', o{1}, oo_to_op_ref_t4, t4))
                t4_obj.oo = [t4_obj.oo t4];
            end
            if isempty(t4_obj.oo)
                if ~isfile(sprintf('oo_avgr1_to_op_%s_avgr1_t4', ref))
                    fv.t4_ident(sprintf('oo_avgr1_to_op_%s_avgr1_t4', ref))
                end
                t4_obj.oo = {sprintf('oo_avgr1_to_op_%s_avgr1_t4', ref)};
            end
            
            %% OC
            
            t4_obj.oc = {};
            oc_glob = this.ocglob();
            oc_to_op_ref_t4 = sprintf('oc_avgr1_to_op_%s_avgr1_t4', ref);
            for c = asrow(oc_glob)
                t4 = sprintf('%s_to_op_%s_avgr1_t4', this.collectionRB.frontOfT4(c{1}), ref);
                mlbash(sprintf('t4_mul %s %s %s', c{1}, oc_to_op_ref_t4, t4))
                t4_obj.oc = [t4_obj.oc t4];
            end
            if isempty(t4_obj.oc)
                if ~isfile(sprintf('oc_avgr1_to_op_%s_avgr1_t4', ref))
                    fv.t4_ident(sprintf('oc_avgr1_to_op_%s_avgr1_t4', ref))
                end
                t4_obj.oc = {sprintf('oc_avgr1_to_op_%s_avgr1_t4', ref)};
            end
            
            deleteExisting('t4_ojb.mat')
            save('t4_obj.mat', 't4_obj')            
            popd(pwd0)
        end
		  
 		function this = SessionResolverToHO(varargin)
 			%% SESSIONRESOLVERTOHO
 			%  @param .

            this = this@mlpet.SessionResolverToTracer(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

