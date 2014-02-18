function iv= procutil_getIvalIndices(ival, dat, varargin)
%PROCUTIL_GETIVALINDICES - Get indices for a given time interval
%
%Synopsis:
% IDX= procutil_getIvalIndices(IVAL, FS, <OPT>)
% IDX= procutil_getIvalIndices(IVAL, DAT, <OPT>)
%
%Arguments:
% IVAL - time interval [start ms, end ms] (or just a point of time)
%         ival can also be a Nx2 sized matrix. In that case the
%         concatenated indices of all ival-columns are returned.
% FS   - sampling interval
% DAT  - data struct containing the fields .fs and .t
% OPT  - Struct or property/value list of optinal properties:
%  'IvalPolicy' [CHAR] 'maximal', 'minimal', or 'sloppy'
%  'Dim'        [DOUBLE] default 1
%
%Returns:
%  IDX   - indices of given interval [samples]


props= {'IvalPolicy'   'maximal'    'CHAR(minimal maximal sloppy)'
        'Dim'          1            '!INT[1]'};

if nargin==0,
  iv= props; return
end

misc_checkType(ival, 'DOUBLE[- 2]');
misc_checkType(dat, '!DOUBLE[1]|STRUCT(fs)');

if length(varargin)==1 && ~isstruct(varargin{1}),
  opt= struct('Dim', {varargin{1}});
else
  opt= opt_proplistToStruct(varargin{:});
end
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if size(ival,1)>1,
  iv= [];
  for kk= 1:size(ival,1),
    newiv= procutil_getIvalIndices(ival(kk,:), dat);
    iv= [iv, newiv];
  end
  return;
end

if isstruct(dat),
  if isfield(dat, 'dim') && length(dat.dim)>1,
    %% first dimension of dat.x comprises different 'virtual' dimensions
    %% that have been clashed
    dati= struct('fs', dat.fs);
    dati.t= dat.t{opt.dim};
    if isfield(dat, 'xUnit'),
      dati.xUnit= dat.xUnit{opt.dim};
    end
    iv= procutil_getIvalIndices(ival, dati);
    return;
  end
  
  if isfield(dat, 'xUnit') && strcmp(dat.xUnit, 'Hz'),
    switch(opt.IvalPolicy),
     case 'maximal',
      ibeg= max([1 find(dat.t<=ival(1))]);
      iend= min([find(dat.t>=ival(2)) length(dat.t)]);
     case 'minimal',
      ibeg= min([find(dat.t>=ival(1)) length(dat.t)]);
      iend= max([1 find(dat.t<=ival(2))]);
     case 'sloppy',
      dd= median(diff(dat.t));
      ibeg= min([find(dat.t>=ival(1)-0.25*dd) length(dat.t)]);
      iend= max([1 find(dat.t<=ival(2)+0.25*dd)]);
    end
    iv= ibeg:iend;
    return
  end
  
  %% TODO !!! -> Revise this code !!!
  iv= procutil_getIvalIndices(ival, dat.fs);
  if isfield(dat, 't'),
    segStart= dat.t(1);
  else
    segStart= 0;
  end
  iv= 1 + iv - segStart*dat.fs/1000;
  if (iv(1))~=round(iv(1))
    iv = ceil(iv);
    iv(end) = [];
  end
  
  %%added by rklein on may 16th 2008
  id0 = find(iv==0);
  iv(id0) = [];  

else
  fs= dat;
  iv= floor(ival(1)*fs/1000):ceil(ival(end)*fs/1000);
end

