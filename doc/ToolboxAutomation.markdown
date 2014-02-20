# Documentation: Automation of Analysis over an Experimental Study


## Table of Contents

* Looping an ERP-Analysis over a Sequence of Experiments: <a href="#Looping-over-a-session">Looping over a session</a>
* Plotting Grand Average ERPs: <a href="#Grand-Averages">Grand Averages</a>
* Compiling the Figures into a PDF via LaTeX: <a href="#Automatic-Latexing">Automatic Latexing</a>


## Preface

The LaTeXing part assumes that a global variable `TEX_DIR` exists, which points
to the `bbci_tex` folder of the SVN with '/' at the end, e.g.,

      TEX_DIR = '/home/blanker/svn/ida/public/bbci_tex/'

The proposed automation works best, when sticking to the following convention:
You should file your sequence of experiments (session) either as 'project' or as
'study'. This is just a formal distinction with the following convention:

* **studies**. Large scale study, typically with external participants,
  targeting at a journal publication.
* **projects**. Experimental studies that are exploratory, and/or for training
  purpose (labrotations, master theses, internships).

Having explained this distinction, the term 'session' will be generally used in
the sequel. In any case, your session needs to have a 'session name'. The Matlab
scripts to analyse the data of the session are stored under
`BCI_DIR/investigation/studies/''{SESSION_NAME}''` or under
`BCI_DIR/investigation/projects/''{SESSION_NAME}''`. The LaTeX files are stored
under `TEX_DIR/studies/''{SESSION_NAME}''`, resp.
`TEX_DIR/projects/''{SESSION_NAME}''`. The (numerous) figures that are
automatically generated are stored in a subdirectory 'pics_auto' thereof, and
should preferably **not** be added to the SVN. However, summarizing figures
(like grand average overview figures) or figures that should be included in
papers can be stored in a subdirectory 'pics' and be added to the SVN.


## Looping an ERP-Analysis over a Sequence of Experiments <a id="Looping-over-a-session"></a>


```matlab
[subdir_list, session_name]= get_session_list('projekt_biomed2010');	
% -> session_name includes the name of the parent folder, in this case 'projects'

results_file= [DATA_DIR 'results/' session_name '/grand_average_ERPs'];

opt_fig= strukt('folder', [TEX_DIR session_name '/pics_auto/'], ...
                'format', 'pdf');

% For each participant, experiments with the following conditions were performed:
taglist= {'Intensify','Rotate','Upsize'};
filelist= strcat('MatrixSpeller', taglist);

colOrder= [0.83 0.67 0; 0.4 0.4 0.4];
clear erp erp_r

for vp= 1:length(subdir_list),
 subdir= subdir_list{vp};
 sbj= subdir(1:find(subdir=='_',1,'first')-1);
 exp_id= strrep(subdir, '_', '');

  % default values
 disp_ival= [-200 1000];
ref_ival= [-200 0];
crit_maxmin= 70;
crit_ival= [100 900];
crit_clab= {'F9,z,10','AF3,4'};
clab= {'Cz','PO7'};

 for ff = 1:length(filelist),
 fprintf('Processing %s - %s.\n', subdir, filelist{ff});
  % The following provides subject-specific file names for the figures.
 opt_fig.prefix= [exp_id '_' taglist{ff} '_'];

  % subject-specific settings: This can be used to specify, e.g., particular thresholds
  % for artifact rejection for particular participants.
  switch(sbj),
  end

  % load data
  clear cnt epo*
  file= [subdir '/' filelist{ff} sbj];
  [cnt, mrk, mnt]= eegfile_loadMatlab(file);

  b= procutil_firlsFilter(0.5, cnt.fs);
  cnt= proc_filtfilt(cnt, b);

  %% artifact rejection based on variance criterion
  mrk= reject_varEventsAndChannels(cnt, mrk, disp_ival, 'verbose', 1);

  % segmentation
  epo= cntToEpo(cnt, mrk, disp_ival);

  %% artifact rejection based on minmax difference criterion on frontal chans
  epo= proc_rejectArtifactsMaxMin(epo, crit_maxmin, ...
           'clab',crit_clab, 'ival',crit_ival, 'verbose',1);

  epo= proc_baseline(epo, ref_ival);
  epo_r= proc_r_square_signed(epo);
  epo_r.className= {'sgn r^2 ( T , NT )'};  %% just make it shorter

  fig_set(1);
  constraint= ...
      {{-1, [100 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
       {1, [200 350], {'P3-4','CP3-4','C3-4'}, [200 400]}, ...
       {1, [400 500], {'P3-4','CP3-4','C3-4'}, [350 600]}};
  [ival_scalps, nfo]= ...
      select_time_intervals(epo_r, 'visualize', 1, 'visu_scalps', 1, ...
	                            'title', [sbj ': ' taglist{ff}], ...
                            'clab',{'not','E*','Fp*','AF*'}, ...
                            'constraint', constraint);
  printFigure('r_matrix', [18 13], opt_fig);
  ival_scalps= visutil_correctIvalsForDisplay(ival_scalps, 'fs',epo.fs);

  fig_set(3)
  H= grid_plot(epo, mnt, defopt_erps, 'colorOrder',colOrder);
  grid_addBars(epo_r, 'h_scale',H.scale);
  printFigure(['erp'], [19 12], opt_fig);

  fig_set(2);
  H= scalpEvolutionPlusChannel(epo, mnt, clab, ival_scalps, ...
                               defopt_scalp_erp2, ...
                               'colorOrder',colOrder);
  grid_addBars(epo_r);
  printFigure(['erp_topo'], [20  4+5*size(epo.y,1)], opt_fig);

  fig_set(4, 'Resize',[1 2/3]);
  scalpEvolutionPlusChannel(epo_r, mnt, clab, ival_scalps, ...
                            defopt_scalp_r2);
  printFigure(['erp_topo_r'], [20 9], opt_fig);

% save averages for calculating grand averages later
  erp{vp,ff}= proc_average(epo);
  erp_r{vp,ff}= epo_r;

end
end

save(results_file, 'erp','erp_r', 'clab', ...
     'session_name', 'subdir_list','filelist', 'taglist', 'mnt', 'opt_fig');

```


## Plotting Grand Average ERPs <a id="Grand-Averages"></a>
	
**The function `proc_grandAverage`** and some other functions need an update by
Stefan, such that calculating the grand average of signed-$r^2$ values is
weighted inversely with the variance.


```matlab
load(results_file);       % as defined in the example above

ival_scalps= [180 230; 250 350; 400 500];

% find unified scalings for all plots
range_grid= visutil_commonRangeForGA(erp, 'nice_range_erp',10);
range= visutil_commonRangeForGA(erp, 'clab_erp', clab, ...
                                'ival_scalp',ival_scalps);
range_r= visutil_commonRangeForGA(erp_r, 'clab_erp', clab, ...
                                'ival_scalp',ival_scalps);

for ff = 1:length(filelist),
  opt_fig.prefix= ['grand_average_ERPs_' taglist{ff} '_'];
  erp_ga= proc_grandAverage(erp{:,ff});
  erp_r_ga= proc_grandAverage(erp_r{:,ff});

  fig_set(1);
  grid_plot(erp_ga, mnt, defopt_erps, 'colorOrder',colOrder, ...
            'yLim', range_grid.erp);
  printFigure('erp', [19 12]*1.3, opt_fig);

  fig_set(3, 'Resize',[2/3 1]);
  head= mnt_restrictMontage(mnt, 'AF3,4','F7,z,8','FT7,8','FC3,4','C5,z,6', ...
                           'TP7,8','CP3,4','Pz','PO7,8','Oz');
  head= mnt_scalpToGrid(head, 'oversize',[1.2 1.6], 'pos_correction', 1, ...
                        'scale_pos',[0.1 -0.1], 'legend_pos',[1 -0.1]);
  erp_head= proc_selectChannels(erp_ga, head.clab);
  H= grid_plot(erp_head, head, defopt_erps, 'head_mode', 1, ...
               'colorOrder', colOrder, ...
              'lineWidth', 1.5, ...
              'scalePolicy', range_grid.erp, ...
              'oversizePlot',1.25);
  printFigure('erp_head', [15 15], opt_fig);

  fig_set(2); clf;
  H= scalpEvolutionPlusChannel(erp_ga, ...
                               mnt, clab, ival_scalps, ...
                              defopt_scalp_erp2, ...
                               'colorOrder',colOrder, ...
                               'yLim', range.erp, ...
                               'colAx', range.scalp);	
  printFigure('erp_topo', [25 16], opt_fig);

 fig_set(4, 'Resize',[1 2/3]);
  H= scalpEvolutionPlusChannel(erp_r_ga, mnt, clab, ival_scalps, ...
                               defopt_scalp_r2, ...
                               'channelAtBottom', 1, ...
                               'yLim', range_r.erp, ...
                               'colAx', range_r.scalp);
   printFigure('erp_r_topo', [25 10.5], opt_fig);
end
```


## Compiling the Figures into a PDF via LaTeX  <a id="Automatic-Latexing"></a>

Before turning to the LaTeX side, you should run the following command once in
Matlab:

	list_for_tex_loop(session_name)

Here, `session_name` should the variable that is returned as second argument of
the function `get_session_list` which includes the parent directory 'studies' or
'projects', see above. The function `list_for_tex_loop` saves a files named
`subject_loop.tex` in the corresponding session folder in TEX_DIR. This tiny
LaTeX file can be included in your LaTeX file to compile the figures of all
participants in a loop. An example LaTeX file looks like this:


```latex
\documentclass[a4paper,11pt]{article}
\usepackage[width=18cm,height=27cm,footskip=0.5cm,bottom=1cm]{geometry}
\usepackage[latin1]{inputenc}
\usepackage{latexsym,amsmath,amssymb,amsfonts}
\usepackage[ngerman,english]{babel}
\usepackage{graphicx}
\usepackage{float,afterpage}
\usepackage{hyperref,fancyheadings}

\newcommand{\graf}[2][1]{\begin{center}\includegraphics[width=#1\linewidth]{#2}\end{center}}

\makeatletter
\newcommand{\forloopvar}[3]{\@for#1:=#2\do{#3}}
\makeatother
% \forloop[Variablenname, default \loopvar]{Kommaliste}{Aktion}
\newcommand{\forloop}[3][\loopvar]{\forloopvar{#1}{#2}{#3}}

\setlength{\textfloatsep}{5pt plus 2pt minus 3pt}
\graphicspath{{pics_auto/}}

\begin{document}
\renewcommand{\topfraction}{0.99}
\renewcommand{\bottomfraction}{0.99}
\renewcommand{\textfraction}{0.01}

\section{Grand Average}

\newcommand*{\innerrumpf}{
 \lhead{Grand Average}
 \rhead{\paradigm}
 \graf[0.95]{grand_average_ERPs_\paradigm_erp}
 \graf[0.7]{grand_average_ERPs_\paradigm_erp_topo}
 \graf[0.7]{grand_average_ERPs_\paradigm_erp_r_topo}
 \clearpage
}

\forloop[\paradigm]{Intensify,Rotate,Upsize}{%
  \innerrumpf
}

\renewcommand*{\innerrumpf}{
 \rhead{\paradigm}
 \graf{\subject_\paradigm_erp}
 \graf[0.7]{\subject_\paradigm_erp_topo}
 \graf[0.7]{\subject_\paradigm_erp_topo_r}
 \clearpage
}

\newcommand*{\outerrumpf}{
 \section{\emph{\subject}}
 \lhead{\emph{\subject}}
 \enlargethispage{0.5cm} %% to account for section headline
\forloop[\paradigm]{Intensify,Rotate,Upsize}{%
   \innerrumpf
 }
}
\input{subject_loop.tex}

\renewcommand*{\subject}
\end{document}
```

The compilation of the LaTeX file can be run from matlab in the following way
(assuming the file above to be called 'investigate_ERPs.tex'):


```matlab
if isunix,
  latex_file= [TEX_DIR session_name filesep 'investigate_ERPs'];
  [filepath,filename]= fileparts(latex_file);
  cmd= sprintf('cd %s; LD_LIBRARY_PATH="" pdflatex %s %s', ...
               filepath, '-interaction nonstopmode', filename);
  unix(cmd);
end
```
