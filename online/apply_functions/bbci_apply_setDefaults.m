function bbci= bbci_apply_setDefaults(bbci, STRICT)
%BBCI_APPLY_SETDEFAULTS - Set default values in bbci structure for bbci_apply
%
%Synopsis:
%  BBCI= bbci_apply_setDefaults
%  BBCI= bbci_apply_setDefaults(BBCI)
%
%Arguments:
%  BBCI - Structure of bbci_apply which specifies processing and 
%      classification, type 'help bbci_apply_structures' for detailed
%      information about the fields of this structure.
%
%Output:
%  BBCI - Updated bbci structure

% 02-2011 Benjamin Blankertz


global BTB

if nargin==0,
  bbci= [];
end
if nargin<2,
  STRICT= false;
end

props= {'calibrate'       struct   'STRUCT'
        'source'          struct   'STRUCT'
        'marker'          struct   'STRUCT'
        'signal'          struct   'STRUCT'
        'feature'         struct   'STRUCT'
        'classifier'      struct   'STRUCT'
        'control'         struct   'STRUCT'
        'feedback'        struct   'STRUCT'
        'log'             struct   'STRUCT'
        'adaptation'      struct   'STRUCT'
        'quit_condition'  struct   'STRUCT'
	'trigger'         struct   'STRUCT'
       };
bbci= opt_setDefaults('bbci', props);


props= {'acquire_fcn'           @bbci_acquire_bv   '!FUNC'
        'acquire_param'         {}                 'CELL'
        'min_blocklength'       40                 '!DOUBLE[1]'
        'clab'                  '*'                'CHAR|CELL{CHAR}'
        'record_signals'        0                  '!BOOL'
        'record_basename'       ''                 'CHAR'
        'record_param'          {}                 'CELL'
        'marker_mapping_fcn'    []                 'FUNC'
        'log'                   struct             'STRUCT'
       };
bbci.source= opt_overwriteVoids(bbci.source, 'min_blocklength', props);
bbci.source= opt_overwriteVoids(bbci.source, 'record_signals', props);
[bbci.source, isdefault_source]= opt_setDefaults('bbci.source', props);
% this should be removed again:
if length(bbci.source)==1 && ...
      isequal(bbci.source.acquire_fcn, @bbci_acquire_bv) && ...
      isdefault_source.acquire_param,
  bbci.source.acquire_param= {'fs', 100};
end
for k= 1:length(bbci.source)
  props= {'output'         0           '!BOOL|CHAR(screen file screen&file)'
          'data_packets'   0           '!BOOL'
          'markers'        1           '!BOOL'
          'time_fmt'       '%08.3fs'   'CHAR'
         };
  bbci.source(k).log= opt_setDefaults('bbci.source(k).log', props);
end


props= {'queue_length'   100   '!INT'
       };
bbci.marker= opt_setDefaults('bbci.marker', props);


props= {'source'        1         '!INT'
        'clab'          '*'       '!CHAR|CELL{CHAR}'
        'buffer_size'   5*1000    '!INT[1]'
        'proc'          {}        'CELL'
        'fcn'           []        'FUNC|CELL{FUNC}'
        'param'         {}        'CELL'
       };
bbci.signal= opt_overwriteVoids(bbci.signal, 'source', props);
bbci.signal= opt_overwriteVoids(bbci.signal, 'clab', props);
bbci.signal= opt_setDefaults('bbci.signal', props);
opt_checkExclusiveProps('bbci.signal', {'proc','fcn'; 'proc','param'});
bbci.signal= bbciutil_transformProc2FcnParam(bbci.signal);


props= {'signal'         1      '!INT[1]'
        'ival'           []     'DOUBLE[2]'
        'proc'           {}     'CELL'
        'fcn'            []     'FUNC|CELL{FUNC}'
        'param'          {}     'CELL'
       };
if STRICT,
  props{2,3}= '!DOUBLE[2]';
end
bbci.feature= opt_overwriteVoids(bbci.feature, 'signal', props);
bbci.feature= opt_setDefaults('bbci.feature', props);
opt_checkExclusiveProps('bbci.feature', {'proc','fcn'; 'proc','param'});
bbci.feature= bbciutil_transformProc2FcnParam(bbci.feature);


props= {'feature'     1                             '!INT'
        'fcn'         @apply_separatingHyperplane   'FUNC'
        'C'           struct                        '!STRUCT'
       };
bbci.classifier= opt_overwriteVoids(bbci.classifier, 'feature', props);
bbci.classifier= opt_setDefaults('bbci.classifier', props);


props= {'classifier'     1      '!INT'
        'proc'           {}     'CELL'
        'fcn'            ''     'FUNC'
        'param'          {}     'CELL'
        'source_list'    [1]    'INT'
        'condition'      []     'STRUCT(marker)|STRUCT(interval)'};
bbci.control= opt_overwriteVoids(bbci.control, 'classifier', props);
bbci.control= opt_setDefaults('bbci.control', props);
opt_checkExclusiveProps('bbci.control', {'proc','fcn'; 'proc','param'});

for ic= 1:length(bbci.control),
  cfy_list= bbci.control(ic).classifier;
  feat_list= [bbci.classifier(cfy_list).feature];
  cp_list= [bbci.feature(feat_list).signal];
  bbci.control(ic).source_list= unique([bbci.signal(cp_list).source],'legacy');
  if isempty(bbci.control(ic).condition),
    if any(max(cat(1, bbci.feature(feat_list).ival)) > 0),
      error('bbci.feature.ival extends to future data');
    end
  else
    if isfield(bbci.control(ic).condition, 'marker')
      if length(bbci.control(ic).source_list) > 1,
        error(['Controls that are conditioned on markers may acquire ' ...
               'signals only from one source.']);
      end
      ivals= cat(1, bbci.feature(feat_list).ival);
      props= {'marker'     []                     'DOUBLE|CELL{CHAR}'
              'overrun'    max([0; ivals(:,2)])   '!DOUBLE[1]'};
      bbci.control(ic).condition= ...
          opt_setDefaults('bbci.control(ic).condition', props);
    else
      bbci.control(ic).condition.marker= [];
      if ~isfield(bbci.control(ic).condition, 'interval'),
        error(['If bbci.control.condition is nonempty, it must either ' ...
               'have a field ''marker'', or ''interval''.']);
      end
      misc_checkType(bbci.control(ic).condition.interval, '!DOUBLE[1]', ...
                     'bbci.control(ic).condition.interval');
      if any(max(cat(1, bbci.feature(feat_list).ival)) > 0),
        error('bbci.feature.ival extends to future data');
      end
    end
  end
end
bbci.control= bbciutil_transformProc2FcnParam(bbci.control);


props= {'control'     1             '!INT'
        'receiver'    ''            'CHAR(pyff matlab tobi_c udp osc lsl)'
        'fcn'         []            'FUNC'
        'opt'         []            'STRUCT'
        'log'         struct        'STRUCT'
        'host'        '127.0.0.1'   'CHAR'
        'port'        12345         'INT'
       };
bbci.feedback= opt_overwriteVoids(bbci.feedback, 'control', props);
[bbci.feedback, isdefault]=  opt_setDefaults('bbci.feedback', props);
% defaults for bbci.feedback.log are set below
% (because it refers to bbci.log)

for k= 1:length(bbci.feedback),
  switch(bbci.feedback(k).receiver),
   case 'pyff',
    props= {'geometry'        BTB.Acq.Geometry      'INT[4]'
           };
   case 'matlab',
    props= {'geometry'        BTB.Acq.Geometry      'INT[4]'
            'trigger_fcn'     @trigger_matlabSoft   'FUNC'
            'trigger_param'   {}                    'CELL'
           };
   otherwise,
		props= {};
  end
  bbci.feedback(k).opt= opt_setDefaults(bbci.feedback(k).opt, props);
end


props= {'active'            1                   '!BOOL'
        'mode'              'classifier'        'CHAR(classifier everything_at_once)'
        'classifier'        1                   '!INT'
        'proc'              []                  'CELL'
        'fcn'               []                  'FUNC'
        'param'             {}                  'CELL'
        'folder'            BTB.Tp.Dir          'CHAR'
        'file'              'bbci_adaptation'   'CHAR'
        'save_everytime'    0                   '!BOOL'
        'load_classifier'   0                   '!BOOL'
        'log'               struct('output','screen')   'STRUCT(output)'
       };
bbci.adaptation= opt_overwriteVoids(bbci.adaptation, 'classifier', props);
[bbci.adaptation, adapt_default]= opt_setDefaults('bbci.adaptation', props);
opt_checkExclusiveProps('bbci.adaptation', {'proc','fcn'; 'proc','param'});

% Assign filename according to the name of the adaptation function:
for k= 1:length(bbci.adaptation),
  if adapt_default.file && ~isempty(bbci.adaptation(k).fcn),
    bbci.adaptation(k).file= func2str(bbci.adaptation(k).fcn);
  end
  if adapt_default.active && isempty(bbci.adaptation(k).fcn),
    bbci.adaptation(k).active= 0;
  end
end
% For multiple adapatation: if all filenames are the same, append
% the index number to make them distinct.
if length(bbci.adaptation)>1,
  fnames= {bbci.adaptation.file};
  if all(cellfun(@(x) strcmp(x,fnames{1}), fnames)),
    for k= 1:length(bbci.adaptation),
      bbci.adaptation(k).file= [bbci.adaptation(k).file, sprintf('-%02d', k)];
    end
  end
end
bbci.adaptation= bbciutil_transformProc2FcnParam(bbci.adaptation);


if all(cellfun(@isempty, {bbci.feedback.receiver})),
  default_output= 'screen';
else
  default_output= 0;
end
header_line= '# Logfile of BBCI online - <TIME>';
props= {'output'       default_output     '!BOOL|CHAR(screen file screen&file)'
        'folder'       BTB.Tp.Dir         'CHAR'
        'file'         'bbci_apply_log'   'CHAR'
        'header'       {header_line}      'CELL{CHAR}'
        'force_overwriting'   0           '!BOOL'
        'time_fmt'     '%08.3fs'          'CHAR'
        'clock'        0                  '!BOOL'
        'classifier'   0                  '!BOOL'
        'markers'      0                  '!BOOL'
       };
bbci.log= opt_setDefaults('bbci.log', props);
if ~strcmp(bbci.log.header{1}, header_line),
  dim= min(find(size(bbci.log.header)>1));
  if isempty(dim), 
    dim= 1;
  end
  bbci.log.header= cat(dim, {header_line}, bbci.log.header);
end


for k= 1:length(bbci.feedback),
  if length(bbci.feedback)>1,
    no_str= sprintf('_#%d', k);
  else
    no_str= '';
  end
  header_line= ['# Log file of BBCI Feedback' no_str ' - <TIME>'];
  props= {'output'       0                '!BOOL|CHAR(screen file screen&file)'
          'folder'       bbci.log.folder  'CHAR'
          'file'         ''               'CHAR'
          'header'       {header_line}    'CELL{CHAR}'
          'force_overwriting'   0         '!BOOL'
         };
  bbci.feedback(k).log= opt_setDefaults('bbci.feedback(k).log', props);
  if isempty(bbci.feedback(k).log.file),
    if strcmp(bbci.feedback(k).receiver, 'matlab'),
      bbci.feedback(k).log.file= [func2str(bbci.feedback(k).fcn) no_str '_log'];
    else
      if ~isequal(bbci.feedback(k).log.output, 0),
        warning('feedback logging works only for matlab-based feedbacks');
        bbci.feedback(k).log.output= 0;
      end
    end
  end
end


props= {'running_time'    inf    '!DOUBLE[1]'
        'marker'          []     'INT|CELL{CHAR}'
       };
bbci.quit_condition= opt_setDefaults('bbci.quit_condition', props);


props= {'fcn'     @bbci_trigger_print   '!FUNC'
        'param'   {}                    'CELL'};
bbci.trigger= opt_setDefaults('bbci.trigger', props);
