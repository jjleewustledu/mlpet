% +MLPET
%
% Files
%   AbstractAutoradiographyClient  - 
%   AbstractAutoradiographyTrainer - ABSTRACTTRAINER   
%   AbstractBetaCurve              - 
%   AbstractLegacyBetaCurve        - 
%   AbstractWellData               - 
%   AutoradiographyBuilder         - is the abstract interface for Autoradiography builders
%   AutoradiographyBuilder2        - 
%   AutoradiographyDB              - 
%   AutoradiographyDirector        - uses the builder design pattern to separate the processes/algorithms  
%   AutoradiographyTester          - 
%   AutoradiographyTrainer         - 
%   AutoradiographyWorker          - 
%   Blood                          - 
%   Bloodxlsx                      - 
%   BrainWaterKernel               - BRAINWATERKERNEL
%   CRT                            - objectifies Snyder-Videen *.crv files, which directly records beta-detected events from an arterial line.
%   CRV                            - objectifies Snyder-Videen *.crv files, which directly records beta-detected events from an arterial line.
%   CRVAutoradiography             - CRVAUTORADIOGRAPHY
%   CRVDCVAutoradiography          - CRVDCVAutoradiography
%   CRVDeconvolution               - 
%   DCV                            - objectifies Snyder-Videen *.dcv files, replacing the first two count measurements with the third,
%   DCVByGammas                    - 
%   DecayCorrectedCRV              - objectifies Snyder-Videen *.crv files with positron decay-correction.  
%   DecayCorrectedEcat             - implements mlpet.IScannerData for data from detection array of Ecat Exact HR+ scanners, then
%   DecayCorrection                - 
%   DSCAutoradiography             - DSCAUTORADIOGRAPHY
%   DSCHerscAutoradiography        - DSCHERSCAUTORADIOGRAPHY
%   DTA                            - objectifies direct arterial sampling recorded in Videen *.dta files.   
%   EcatExactHRPlus                - implements mlpet.IScannerData for data from detection array of Ecat Exact HR+ scanners.
%   IBetaCurve                     - IWELLDATA   
%   IBloodData                     - 
%   IDecayCorrection               - 
%   ILegacyBetaCurve               - 
%   ImgRecParser                   - 
%   IScannerData                   - 
%   IWellData                      - 
%   Laif2Ecat                      - 
%   NonquantitativeCOSS            - constructs non-quantitative OEF maps according to:
%   O15Builder                     - O15Builder is a concrete builder for PET with [^15O] tracers; 
%   O15Director                    - is the client director that specifies algorithms for creating PET imaging objects;
%   OCCRVAutoradiography           - OCCRVAUTORADIOGRAPHY
%   PETAlignmentBuilder            - 
%   PETAlignmentDirector           - 
%   PETAutoradiography             - PETAUTORADIOGRAPHY
%   PETBuilder                     - is a concrete builder for all PET tracers
%   PETControlsDirector            - ... 
%   PETDirector                    - is the client wrapper for building PET imaging analyses; 
%   PETHerscAutoradiography        - PETHERSCAUTORADIOGRAPHY
%   PETIO                          - 
%   PETMake                        - makes typical FSL targets for image analysis
%   TSC                            - objectifies Mintun-Markham *.tsc files for use with glucose metabolism calculations.   
%   TSC_np755                      - objectifies Mintun-Markham *.tsc files for use with calculations on data from np755.  
%   TSCFiles                       - 
%   UncorrectedDCV                 - 
%   VideenAutoradiography          - VideenAutoradiography
