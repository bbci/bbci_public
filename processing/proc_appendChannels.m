function dat= proc_appendChannels(dat, dat_append,varargin)
%dat= proc_appendChannels(dat, dat_append,<chanName>)
%
% IN   dat        - data structure of continuous or epoched data
%      dat_append - same data structure as dat, to be appended.
%                   Alternatively a single vector or an N x p matrix, where
%                   N is the length of the dat.x field and p is the number
%                   of new channels. For epoched data, N x ep or N x p x ep
%                   where ep is the number of epochs.
%      chanName   - If dat_append is a vector, chanName is the name to be
%                   entered in the .clab field. If multiple channels are
%                   added, chanName should be a cell array of strings.
%
% OUT  dat        - a miracle
%
%Example
%  cnt1 = file_readBV(file1);   %load EEG-data in BV-format
%  cnt2 = file_readBV(file2);   %load EEG-data in BV-format
% append data structures: (t
%    cnt_app = proc_appendChannels(cnt1 , cnt2)
% append 2 channels with random values to cnt1:
%    cnt_app = proc_appendChannels(cnt1 , rand(size(cnt1.x, 1),2), {'randChan1', 'randChan2'} );

%        Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming

if nargin==0,
  dat = []; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab)'); 
misc_checkType(dat_append, 'STRUCT(x clab)|DOUBLE[2- 1-]|DOUBLE[2- 1- 1-]');

if isempty(dat)
    dat = dat_append;
    return
elseif isempty(dat_append)
    return
else
  if ~isstruct(dat_append),  %-- dat_append is a vector or matrix
    if nargin <= 2,
      error('Provide labels for new channels');
    end
    chanName = varargin{1};
    if ~iscell(chanName),
      chanName= {chanName};
    end
    tmp= dat_append;
    dat_append= struct;
    dat_append.x= tmp;
    dat_append.clab= chanName(:)';
  end
  
  if isfield(dat,'t') && iscell(dat.t)
    data_dim = size(dat.t,2);
  else
    data_dim = 1;
  end;

  dat.x= cat(data_dim+1, dat.x, dat_append.x);
  dat.clab= cat(2, dat.clab, dat_append.clab);

  if isfield(dat,'p')
    if data_dim ~= 1
      warning('not yet tested with data_dim ~= 1 !!! remove this warning if it works, fix it otherwise.')
    end
    dat.p = cat(data_dim+1, dat.p, dat_append.p);
  end
  if isfield(dat,'V')
    if data_dim ~= 1
      warning('not yet tested with data_dim ~= 1 !!! remove this warning if it works, fix it otherwise.')
    end
    dat.V = cat(data_dim+1, dat.V, dat_append.V);
  end
end
