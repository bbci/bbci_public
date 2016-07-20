function [cnt, mrk]= proc_appendCnt(cnt, cnt2, mrk, mrk2, varargin)
%PROC_APPENDCNT - Append Continuous EEG Data
%
%Synopsis:
% CNT= proc_appendCnt(CNT1, CNT2);
% CNT= proc_appendCnt({CNT1, ...});
% [CNT, MRK]= proc_appendCnt(CNT1, CNT2, MRK1, MRK2);
% [CNT, MRK]= proc_appendCnt({CNT1, ...}, {MRK1, ...});
%
%Arguments:
%  CNT:  STRUCT       - Continuous data (see file_readBV, file_loadMatlab)
%  CNT2: STRUCT       -  Continuous data to be appended
%  MRK:  STRUCT       - Marker structure, with obligatory field 'time',
%                       which specifies the time points which define the t=0
%                       for each segment that is cut out from the continuous
%                       signals.  (OPTIONAL)
%  MRK2:  STRUCT      - marker structure of the CNT2 to be appended to CNT
%                       (OPTIONAL)
%  OPT:  PROPLIST     - Struct or property/value list of optional properties:
%    'Channelwise': BOOL append data channel-wise (different programming
%                       procedure, but same result), DEFAULT 0
%
%Returns:
%  EPO -  an updated structure of Continuous EEG Data 
%  MRK -  an updated MRK structure, if MRK1 and MRK2 is specified
%
%Examples
%  [cnt1, mrk1]= file_readBV(file1);   %load EEG-data from file1
%  [cnt2, mrk2]= file_readBV(file2);   %load EEG-data from file2
%  [cnt3, mrk3]= file_readBV(file3);   %load EEG-data from file3
%  cnt12 = proc_appendCnt(cnt1, cnt2); %append EEG-data only
%  [cnt12, mrk12] = proc_appendCnt(cnt1, cnt2, mrk1, mrk2); 
%           %append EEG-data and marker of file 1 and file2
%  [cnt_all, mrk_all] = proc_appendCnt({cnt1, cnt2, cnt3}, {mrk1, mrk2, mrk3}); 
%           append EEG-data and marker of all 3 files
%
% SEE proc_appendEpochs, proc_appendChannels

% ??-200? Benjamin Blankertz
% 06-2012 Johannes Hoehne   - Updated the help documentation & probs


props= {'Channelwise',          0       'BOOL'};

if nargin==0,
  cnt = props; return
end

%The following would work, but a history doesn't make sense in this context
%anyway.
% if iscell(cnt)
%     cnt=cellfun(@misc_history,cnt,'UniformOutput',0);
% else 
%     cnt = misc_history(cnt);
% end

misc_checkType(cnt, 'STRUCT(title x clab fs)|CELL{STRUCT}'); 
misc_checkType(cnt2, 'STRUCT(title x clab fs)|CELL{STRUCT}');
misc_checkTypeIfExists('mrk','STRUCT(time y)|CELL{STRUCT}');
misc_checkTypeIfExists('mrk2','STRUCT(time y)|CELL{STRUCT}');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if iscell(cnt),
  %% iterative concatenation: not very effective
  if nargin>2,
    error('if the first argument is a cell: max 2 arguments');
  end
  cnt_cell= cnt;
  if nargin>1,
    mrk_cell= cnt2;
    if ~iscell(mrk_cell) || length(mrk_cell)~=length(cnt_cell),
      error('cell arrays for CNT and MRK do not match');
    end
  else
    mrk_cell= repmat([], 1, length(cnt_cell));
  end
  cnt= [];
  mrk= [];
  for cc= 1:length(cnt_cell),
    [cnt, mrk]= proc_appendCnt(cnt, cnt_cell{cc}, mrk, mrk_cell{cc});
  end
  return;
end

if exist('mrk','var'),
  if ~exist('mrk2','var'),
    error('you have to provide either no or two marker structures');
  end
end

if isempty(cnt),
  cnt= cnt2;
  if exist('mrk','var'),
    mrk= mrk2;
  end
  return;
end

if cnt.fs~=cnt2.fs,
  error('mismatch in cnt sampling rates');
end

if ~isequal(cnt.clab, cnt2.clab),
  sub= intersect(cnt.clab, cnt2.clab,'legacy');
  if isempty(sub),
    error('data sets have disjoint channels');
  else
    msg= sprintf('mismatch in channels, using common subset (%d channels)', ...
                 length(sub));
    warning(msg);
  end
  cnt= proc_selectChannels(cnt, sub);
  cnt2= proc_selectChannels(cnt2, sub);
end

T= size(cnt.x, 1);  % Length in samples
C= size(cnt.x, 2);
if opt.Channelwise
  T2= size(cnt2.x, 1);
  for ic= 1:C
    cnt.x(1:T+T2,ic) = cat(1,cnt.x(1:T,ic),cnt2.x(:,ic));
  end
else
  cnt.x= cat(1, cnt.x, cnt2.x);
end
if ~strcmp(cnt.title, cnt2.title) && ...
    isempty( str_patternMatch('* et al', cnt.title) ),
  cnt.title= [cnt.title ' et al'];
end
if isfield(cnt, 'file') && isfield(cnt2, 'file'),
  if ~iscell(cnt.file), cnt.file= {cnt.file}; end
  if ~iscell(cnt2.file), cnt2.file= {cnt2.file}; end
  cnt.file= cat(2, cnt.file, cnt2.file);
end

if exist('mrk','var') && ~isempty(mrk),
  mrk= mrk_appendMarkers(mrk, mrk2, T*1000/cnt.fs);
end
