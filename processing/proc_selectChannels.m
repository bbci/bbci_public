function [dat2, W]= proc_selectChannels(dat, varargin)
%PROC_SELECTCHANNELS - Select channels from continuous or epoched data
%
%Synopsis:
%   DAT = proc_selectChannels(DAT,CHANS,<...>)
%
%Arguments:
% DAT:      STRUCT      - data structure of continuous or epoched data
% CHANS:	CELL        - cell array or list of channels to be selected,
%                         see util_chanind for format
%Returns:
% DAT - updated data structure
%
% See also util_chanind
if nargin==0
    dat2=[]; return
end

misc_checkType(dat, '!STRUCT(x clab)'); 
dat = misc_history(dat);

if isnumeric(varargin{1})
  chans= varargin{1};
else
  chans= util_chanind(dat.clab, varargin{:}); 
end
if nargout>1,
  W= eye(length(dat.clab));
  W= W(:,chans);
end

if isfield(dat,'xUnit') && iscell(dat.xUnit)
  restdims = size(dat.x);
  dim1=1;
  for idx=1:length(restdims)
    dim1 = dim1 * restdims(idx);
    if dim1 == prod(dat.dim) 
      restdims = restdims((idx+1):end);
      break;
    end;
  end;
  dat.x = reshape(dat.x,[prod(dat.dim) restdims]);
end

dat2= rmfield(dat, 'x');
dat2.x= dat.x(:,chans,:);

if isfield(dat,'xUnit') && iscell(dat.xUnit)
  restdims = size(dat.x);
  restdims = restdims(2:end);
  dat.x = reshape(dat.x,[dat.dim restdims]);
  restdims2 = size(dat2.x);
  restdims2 = restdims2(2:end);
  dat2.x = reshape(dat2.x,[dat.dim restdims2]);
end

if isfield(dat,'clab')
  dat2.clab= dat.clab(chans);
end
if isfield(dat,'scale')
  dat2.scale= dat.scale(chans);
end
if isfield(dat,'p')
  dat2.p= dat.p(:,chans);
end
if isfield(dat,'V')
  dat2.V= dat.V(:,chans);
end
if isfield(dat,'sgnlogp')
  dat2.sgnlogp= dat.sgnlogp(:,chans);
end
