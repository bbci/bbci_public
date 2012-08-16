function [out, iv]= proc_selectIval(dat, ival, varargin)
%PROC_SELECTIVAL - Select subinterval from epoched data
%
%Synopsis:
% OUT= proc_selectIval(DAT, IVAL)
% OUT= proc_selectIval(DAT, MSEC, <POS>)
% OUT= proc_selectIval(DAT, IVAL/MSEC, OPT)
%
% selects the time segment given by ival ([start_ms end_ms]), or the
% segment of length msec (scalar) at position defined by 'Pos'.
%
%Arguments:
% DAT  - data structure of continuous or epoched data
% IVAL - time segment to be extracted
% MSEC - length of time segment to e extracted
% POS  - relative position of time segment, if msec was specified
%        before, 'beginning', 'relative' or 'end' (default)
% OPT - struct or property/value list of optional properties:
%  'Pos': like POS above.
%  'Dim': dimension in which the subinterval is selected, default 1.
%  
% OUT  dat  - updated data structure

% bb, ida.first.fhg.de

props= {'Pos'      'beginning'  '!CHAR(beginning end relative)'
        'Dim'       1           '!INT' };
      
if nargin==0,
  dat= props; return
end

if length(varargin)==1 & ~isstruct(varargin{1}),
  opt= strukt('Pos', varargin{1});
else
  opt= propertylist2struct(varargin{:});
end

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType('dat', 'STRUCT(x fs)'); 
misc_checkType('ival','DOUBLE[2]'); 

%%                
if length(ival)==1 | isequal(opt.Pos, 'relative'),
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
  iv= getIvalIndices(ival, dat, opt);
end

out= copy_struct(dat, 'not','x');
sz= size(dat.x);
if isfield(dat, 'dim') & length(dat.dim)>1,
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

if isfield(dat, 'p'),
  out.p= dat.p(iv,:);
end

if isfield(dat, 'V'),
  out.V= dat.V(iv,:);
end
