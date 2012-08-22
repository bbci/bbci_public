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
%  CNT:  STRUCT       - Continuous data (see eegfile_readBV, eegfile_loadMatlab)
%  CNT2: STRUCT       -  Continuous data to be appended
%  MRK:  STRUCT       - Marker structure, with obligatory field 'time',
%                       which specifies the time points which define the t=0
%                       for each segment that is cut out from the continuous
%                       signals.  (OPTIONAL)
%  MRK2:  STRUCT      - marker structure of the CNT2 to be appended to CNT
%                       (OPTIONAL)
%  OPT:  PROPLIST     - Struct or property/value list of optional properties:
%    'channelwise': BOOL append data channel-wise (different programming
%                       procedure, but same result), DEFAULT 0
%
%Returns:
%  EPO -  an updated structure of Continuous EEG Data 
%  MRK -  an updated MRK structure, if MRK1 and MRK2 is specified
%
%Examples
%  [cnt1, mrk1]= eegfile_readBV(file1);   %load EEG-data from file1
%  [cnt2, mrk2]= eegfile_readBV(file2);   %load EEG-data from file2
%  [cnt3, mrk3]= eegfile_readBV(file3);   %load EEG-data from file3
%  cnt12 = proc_appendCnt(cnt1, cnt2); %append EEG-data only
%  [cnt12, mrk12] = proc_appendCnt(cnt1, cnt2, mrk1, mrk2); 
%           %append EEG-data and marker of file 1 and file2
%  [cnt_all, mrk_all] = proc_appendCnt({cnt1, cnt2, cnt3}, {mrk1, mrk2, mrk3}); 
%           append EEG-data and marker of all 3 files
%
% SEE proc_appendEpochs, proc_appendChannels

% ??-200? Benjamin Blankertz
% 06-2012 Johannes Hoehne   - Updated the help documentation & probs

cnt = misc_history(cnt);

props= {'channelwise',          0       'BOOL'};

if nargin==0,
  cnt = props; return
end

misc_checkType(cnt, 'STRUCT(x clab fs)|CELL(STRUCT)'); 
misc_checkType(cnt2, 'STRUCT(x clab fs)|CELL(STRUCT)');

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
    if ~iscell(mrk_cell) | length(mrk_cell)~=length(cnt_cell),
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

if exist('mrk','var'),
  if ~isempty(mrk) & mrk(1).fs~=mrk2(1).fs,
    error('mismatch in mrk sampling rates');
  end
  if ~isempty(mrk) & mrk(1).fs~=cnt.fs,
    error('mismatch between cnt and mrk sampling rates');
  end
end

if ~isequal(cnt.clab, cnt2.clab),
  sub= intersect(cnt.clab, cnt2.clab);
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

T= size(cnt.x, 1);
C= size(cnt.x,2);
if opt.channelwise
  T2= size(cnt2.x, 1);
  for ic= 1:C
    cnt.x(1:T+T2,ic) = cat(1,cnt.x(1:T,ic),cnt2.x(:,ic));
  end
else
  cnt.x= cat(1, cnt.x, cnt2.x);
end
if ~strcmp(cnt.title, cnt2.title),
  cnt.title= [cnt.title ' et al'];
end
if isfield(cnt, 'file') & isfield(cnt2, 'file'),
  if ~iscell(cnt.file), cnt.file= {cnt.file}; end
  if ~iscell(cnt2.file), cnt2.file= {cnt2.file}; end
  cnt.file= cat(2, cnt.file, cnt2.file);
end

if exist('mrk','var') & ~isempty(mrk),
  if isfield(mrk(1),'time') & ~isfield(mrk2(1),'time')
    error('appending dissimilar structs for mrk');
  elseif length(mrk2)>1 || ~iscell(mrk2.type),
    %% mrk2 has format 'StructArray' (see eegfile_readBVmarkers)
    for i = 1:length(mrk2)
      mrk2(i).pos = mrk2(i).pos+T;
    end
    mrk = cat(1,mrk,mrk2);
  else
    mrk2.pos= mrk2.pos + T;
    mrk= mrk_mergeMarkers(mrk, mrk2);
  end
end
