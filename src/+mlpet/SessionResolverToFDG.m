classdef SessionResolverToFDG < handle & mlpet.SessionResolverToTracer
	%% SESSIONRESOLVERTOFDG  

	%  $Revision$
 	%  was created 08-Jan-2020 22:25:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	methods 
        function this = alignCrossModal(this)
            %% ALIGNCROSSMODAL
            %  theFdg,theHo,theOo,theOc
            %  @return t4 in this.t4s:            e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_to_op_fdgv1r1_t4}.
            %  @return resolved in this.product:  e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_op_fdgv1r1.4dfp.hdr}.            

            pwd0     = pushd(this.workpath);  
            
            theHo    = copy(this.alignCommonModal('HO'));
                       theHo.productAverage('HO');      
            
            theOo    = copy(this.alignCommonModal('OO'));
                       theOo.productAverage('OO'); 
            
            theFdg   = copy(this.alignCommonModal('FDG'));
                       theFdg.productAverage('FDG');
            
            prefixes = {theFdg.product{1}.fileprefix ...
                        theHo.product{1}.fileprefix ...
                        theOo.product{1}.fileprefix}; 
            this = copy(theFdg);
            this = this.resolve(prefixes, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'Msktgen', ...
                'client', 'alignCrossModal_this');
            
            that = copy(this);
            that.alignDynamicImages('commonRef', theHo,  'crossRef', this);
            that.alignDynamicImages('commonRef', theOo,  'crossRef', this);
            theFdg = copy(that.alignDynamicImages('commonRef', theFdg, 'crossRef', this)); % TO DO:  remove redundancy
            
            popd(pwd0);    

            theOc = copy(theFdg.alignCrossModalSubset);
            this.packageProduct([that.product theOc.product]);
        end
        function tf   = isfinished(this)
            import mlsystem.DirTool
            pwd0 = pushd(fullfile(this.collectionRB.sessionData.subjectPath, ...
                                  this.collectionRB.sessionData.sessionFolder, ''));
            dt_FDG = DirTool('FDG_DT*.000000-Converted-AC');
            dt_HO  = DirTool('HO_DT*.000000-Converted-AC');
            dt_OO  = DirTool('OO_DT*.000000-Converted-AC');
            dt_OC  = DirTool('OC_DT*.000000-Converted-AC');
            dt_fdg = DirTool('fdg*_op_fdg_on_op_fdg_avgr1.4dfp.img');
            dt_ho  = DirTool('ho*_op_ho*_on_op_fdg_avgr1.4dfp.img');
            dt_oo  = DirTool('oo*_op_oo*_on_op_fdg_avgr1.4dfp.img');
            dt_oc  = DirTool(sprintf('oc*_op_oc*_on_op_fdg*_frames1to%i_avgtr1.4dfp.img', max(this.framesOfSubsetTarget_)));
            popd(pwd0)
            
            tf = ~isempty(dt_FDG.fqdns) && ~isempty(dt_fdg.fqfns) && ...
                 ~isempty(dt_HO.fqdns)  && ~isempty(dt_ho.fqfns) && ...
                 ~isempty(dt_OO.fqdns)  && ~isempty(dt_oo.fqfns) && ...
                 ~isempty(dt_OC.fqdns)  && ~isempty(dt_oc.fqfns);
        end
        function t4_obj = t4_mul(this)
            
            fv = mlfourdfp.FourdfpVisitor;
            pwd0 = pushd(this.workpath);
            
            %% FDG
            
            t4_obj.fdg = {};
            fdg_glob = this.fdgglob(); %('fdgdt[0-9]+_avgtr1_to_op_fdgdt[0-9]+r1_t4');
            fdg_to_op_fdg_t4 = 'fdg_avgr1_to_op_fdg_avgr1_t4';
            for f = asrow(fdg_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4',  this.collectionRB.frontOfT4(f{1}));
                mlbash(sprintf('t4_mul %s %s %s', f{1}, fdg_to_op_fdg_t4, t4))
                t4_obj.fdg = [t4_obj.fdg t4];
            end
            if isempty(t4_obj.fdg)
                if ~isfile('fdg_avgr1_to_op_fdg_avgr1_t4')
                    fv.t4_ident('fdg_avgr1_to_op_fdg_avgr1_t4')
                end
                t4_obj.fdg = {'fdg_avgr1_to_op_fdg_avgr1_t4'};
            end
            
            %% HO
            
            t4_obj.ho = {};
            ho_glob = this.hoglob();
            ho_to_op_fdg_t4 = 'ho_avgr1_to_op_fdg_avgr1_t4';
            for h = asrow(ho_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4', this.collectionRB.frontOfT4(h{1}));
                mlbash(sprintf('t4_mul %s %s %s', h{1}, ho_to_op_fdg_t4, t4))
                t4_obj.ho = [t4_obj.ho t4];
            end
            if isempty(t4_obj.ho)
                if ~isfile('ho_avgr1_to_op_ho_avgr1_t4')
                    fv.t4_ident('ho_avgr1_to_op_ho_avgr1_t4')
                end
                t4_obj.ho = {'ho_avgr1_to_op_ho_avgr1_t4'};
            end
            
            %% OO
            
            t4_obj.oo = {};
            oo_glob = this.ooglob();
            oo_to_op_fdg_t4 = 'oo_avgr1_to_op_fdg_avgr1_t4';
            for o = asrow(oo_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4', this.collectionRB.frontOfT4(o{1}));
                mlbash(sprintf('t4_mul %s %s %s', o{1}, oo_to_op_fdg_t4, t4))
                t4_obj.oo = [t4_obj.oo t4];
            end
            if isempty(t4_obj.oo)
                if ~isfile('oo_avgr1_to_op_oo_avgr1_t4')
                    fv.t4_ident('oo_avgr1_to_op_oo_avgr1_t4')
                end
                t4_obj.oo = {'oo_avgr1_to_op_oo_avgr1_t4'};
            end
            
            %% OC
            
            t4_obj.oc = {};
            oc_glob = this.ocglob();
            oc_to_op_fdg_t4 = glob('oc_avg_sqrtr1_to_op_fdgdt*_frames1to*_avgtr1_t4');
            for c = asrow(oc_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4', this.collectionRB.frontOfT4(c{1}));
                mlbash(sprintf('t4_mul %s %s %s', c{1}, oc_to_op_fdg_t4{1}, t4))
                t4_obj.oc = [t4_obj.oc t4];
            end
            if isempty(t4_obj.oc)
                if ~isfile('oc_avgr1_to_op_oc_avgr1_t4')
                    fv.t4_ident('oc_avgr1_to_op_oc_avgr1_t4')
                end
                t4_obj.oc = {'oc_avgr1_to_op_oc_avgr1_t4'};
            end
            
            deleteExisting('t4_ojb.mat')
            save('t4_obj.mat', 't4_obj')            
            popd(pwd0)
        end
		  
 		function this = SessionResolverToFDG(varargin)
 			%% SESSIONRESOLVERTOFDG
 			%  @param .
 			
 			this = this@mlpet.SessionResolverToTracer(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

