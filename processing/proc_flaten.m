function dat= proc_flaten(dat, varargin)
%PROC_FLATEN - reduce dimensionality of a data struct by stacking
%
%Synopsis:
%dat= proc_flaten(dat)
%
%Arguments:
%   dat   - data struct 
%
%Returns:
%  dat    - data structure where all dimensions in .x except the last one
%           are clashed
%
%Description:
% reshape data matrix to data vector (clash all but last dimensions)
% if an optional parameter force_flaten is given, a single subtrial with 
% size (NxM) will be flatened to NMx1. Default = False.
% use: dat = proc_flaten(dat, 'ForceFlaten', True);
% 
% added support for single trial flatening (Martijn)

props= { 'ForceFlaten'   0    'BOOL'};

if nargin==0,
  dat = props; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x)');
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


if isnumeric(dat),
  % Also flaten the data if it is a plain data matrix
  sz = size(dat);
  dat = reshape(dat, [prod(sz(1:end-1)) sz(end)]); 
elseif isstruct(dat),
  % Old code from the BCI toolbox:
  if isnumeric(dat.x),
    sz = size(dat.x);
    if numel(sz) == 2 && opt.ForceFlaten,
      dat.x = reshape(dat.x, prod(sz), 1);
    else
      dat.x = reshape(dat.x, [prod(sz(1:end-1)) sz(end)]);
    end
  else
    error('Don''t know how to flatten this type of data');
  end
else
  error('Don''t know how to flatten this type of data');
end
