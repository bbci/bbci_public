function [varargout]= proc_selectIval(dat, ival, varargin)
%PROC_SELECTIVAL - Select subinterval from epoched or continuous data
%
%Synopsis:
% EPO= proc_selectIval(EPO, IVAL)
% EPO= proc_selectIval(EPO, MSEC, <POS>)
% EPO= proc_selectIval(EPO, IVAL/MSEC, OPT)
% [CNT, MRK]= proc_selectIval(CNT, MRK, IVAL)
%
% selects the time segment given by ival ([start_ms end_ms]), or the
% segment of length msec (scalar) at position defined by 'Pos'.
%
%Arguments:
% EPO,CNT - data structure of continuous (with markers MRK) or epoched data
% IVAL - time segment to be extracted
% MSEC - length of time segment to be extracted
% POS  - relative position of time segment, if msec was specified
%        before, 'beginning', 'relative' or 'end' (default)
% OPT - struct or property/value list of optional properties:
%  'Pos': like POS above.
%  'Dim': dimension in which the subinterval is selected, default 1.
%  
%Returns:
% EPO,CNT,MRK  - updated data structure

if nargin>=2 && isstruct(ival),
  varargout= cell(1, nargout);
  [varargout{:}]= proc_selectIvalFromCnt(dat, ival, varargin{:});
  return
end

props= {'Pos'      'beginning'  '!CHAR(beginning end relative)'
        'Dim'       1           '!INT' };
props_getIvalIndices= procutil_getIvalIndices;

if nargin==0,
  dat= opt_catProps(props, props_getIvalIndices);
  return
end

if length(varargin)==1 && ~isstruct(varargin{1}),
  opt= struct('Pos', {varargin{1}});
else
  opt= opt_proplistToStruct(varargin{:});
end

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_getIvalIndices);
misc_checkType(dat, 'STRUCT(x fs)'); 
misc_checkType(ival,'DOUBLE[2]'); 
dat= misc_history(dat);

%%                
if length(ival)==1 || isequal(opt.Pos, 'relative'),
  msec= ival;
  switch(lower(opt.Pos)),
   case 'beginning',
    iv= 1 + [0:floor(msec*dat.fs/1000)];
   case 'end',
    iv= size(dat.x,1) + [-ceil(msec*dat.fs/1000):0];
   case 'relative',
    iv= 1 + [floor(msec(1)*dat.fs/1000):ceil(msec(2)*dat.fs/1000)];
   otherwise
    error('unknown position indicator');
  end
else
  opt_x= opt_substruct(opt, props_getIvalIndices(:,1));
  iv= procutil_getIvalIndices(ival, dat, opt_x);
end

out= dat;
sz= size(dat.x);
if isfield(dat, 'dim') && length(dat.dim)>1,
  %% first dimension of dat.x comprises different 'virtual' dimensions
  %% that have been clashed
  xx= reshape(dat.x, [dat.dim sz(2:end)]);
  idx= repmat({':'}, [1 2+length(dat.dim)]);
  idx{opt.Dim}= iv;
  out.dim(opt.Dim)= length(iv);
  out.x= reshape(xx(idx{:}), [out.Dim sz(2:end)]);
else
  sz(1)= length(iv);
  out.x= reshape(dat.x(iv,:), sz);
end

if isfield(dat, 't'),
  if iscell(dat.t),
    out.t= dat.t;
    out.t{opt.Dim}= dat.t{opt.Dim}(iv);
  else
    out.t= dat.t(iv);
  end
end

if isfield(dat, 'p'), out.p= dat.p(iv,:); end
if isfield(dat, 'V'), out.V= dat.V(iv,:); end
if isfield(dat, 'sgnlogp'), out.sgnlogp= dat.sgnlogp(iv,:); end
if isfield(dat, 'se'), out.se= dat.se(iv,:); end

output= {out, iv};
varargout= output(1:nargout);
