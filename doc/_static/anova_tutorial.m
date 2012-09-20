% ANOVA tutorial

% Load ERP data
l=load([DATA_DIR 'results/studies/onlineVisualSpeller/erp_components']);

% The three factors are embedded in the 2nd dimension, need to be un-nested
nlevels = [3 2 3]; % Specify fastest varying levels first (Electrode)
dat = nested2multidata(l.amp,nlevels);

size(dat)

% Perform 3-way repeated-measures ANOVA
[p,t,stats,terms,arg] = rmanova(dat,{'Electrode'  'Status'  'Speller'});

% Tukey-Kramer post-hoc test
comp = multcompare(stats,'estimate','anovan','dimension',[4 ]);
