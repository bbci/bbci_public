%  BBCI Toolbox
%  Copyright  (c) 2001- 2012 Benjamin Blankertz et al.
%% add other authors?/which ones?
%   Berlin Institute of Technology, Neurotechnology Group and Berlin Brain Computer Interface
%% add also Machine Learning group? 
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA. 
%
%  Published reports of research using this code (or a modified version, maintaining a significant 
%  portion of the original code) should cite an article dedicated on this toolbox (to be published soon) 
%  or the following article:
%
%   Blankertz B, Tangermann M, Vidaurre C, Fazli S, Sannelli C, Haufe S, Maeder C, Ramsey LE, Sturm I, 
%   Curio G, MŸller KR, The Berlin Brain-Computer Interface: Non-Medical Uses of BCI Technology, 
%   Open   Access  Front Neuroscience, 4:198, 2010
%   http://www.frontiersin.org/neuroprosthetics/10.3389/fnins.2010.00198/abstract
%% As soon as the an article especially devoted to the explanation of the toolbox is published, 
%% this remark should be replaced by this other article  
%
%    Comments and bug reports are welcome.  Please email to: bbci_tu@ml.cs.tu-berlin.de.
%    We would also appreciate hearing about how you used this code,
%


Requirements: 
- Matlab Version 2007 or later and 
- for data acquisition: BrainVision recorder + a BCI system 

Download the most recent version of the code from
%% insert download link here
and data from
%% insert data download link here
and the PYFF toolbox from
%% insert PYFF download link here
%% will PYFF be packaged into this toolbox?

open matlab and to the BBCI Toolbox head directory
define the following path variables
> DATA_DIR='YOUR_FULL_DATA_DIR'
% here are the files from the recording are dumped in raw format:
> BBCI_RAW_DIR = 'YOUR_FULL_RAW_DIR' 
% here are the files from the recording are dumped in .mat matlab format:
>  BBCI_MAT_DIR ='YOUR_FULL_MAT_DIR' 

% to intialize the toolbox type:
 
> startup_bbci_toolbox

% run the (off-line) demos in the 'demos' directory
> demo_analysis_ERD
% ERP Analysis:
> demo_analysis_ERPs
> demo_analysis_Spectra

%% the following examples to be included:
%% https://wiki.ml.tu-berlin.de/wiki/IDA/BerlinBCI/ToolBox/ToolboxPracticalExamples


