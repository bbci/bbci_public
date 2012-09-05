function out= proc_linearDerivation(dat, A, varargin)
%PROC_LINEARDERIVATION - computes a linear derivation on continuous or
%epoched data
%
%Synopsis:
%out= proc_linearDerivation(dat, A, <OPT>)
%out= proc_linearDerivation(dat, A, <appendix>)
%
%
%Arguments:   
%      dat      - data structure of continuous or epoched data
%      A        - spatial filter matrix [nOldChans x nNewChans]
%      appendix - in case of input-output channel matching
%                 this string is appended to channel labels, default ''
%      OPT      - struct or property/value list of properties:
%       .clab - cell array of channel labels to be used for new channels,
%               or 'generic' which uses {'ch1', 'ch2', ...}
%               or 'copy' which copies the channel labels from input struct.
%       .appendix - (as above) tries to find (naive) channel matching
%               and uses as channel labels: old label plus opt.appendix.
%
%Returns:  
%      dat      - updated data structure
%
% SEE also online_linearDerivation

%        Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming
props= {'clab'          []          'CHAR';
        'prependix'     ''          'CHAR';
        'appendix'      ''          'CHAR'
        };

if nargin==0,
  out = props; return
end

misc_checkType(dat,  'STRUCT(x clab)');
misc_checkType(A, sprintf('DOUBLE[%i -]', size(dat.x,2)));
dat = misc_history(dat);

%%
if length(varargin)==1,
  opt= struct('appendix', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end

[opt, isdefault]= opt_setDefaults(opt, props);

%out= copy_struct(dat, 'not', 'x','clab');
out= dat;

nNewChans= size(A,2);
if ndims(dat.x)==2,
  out.x= dat.x*A;
else
  sz= size(dat.x);
  out.x= reshape(permute(dat.x, [1 3 2]), sz(1)*sz(3), sz(2));  
  out.x= out.x*A;
  out.x= permute(reshape(out.x, [sz(1) sz(3) nNewChans]), [1 3 2]);
end

if ~isdefault.clab,
  if isequal(opt.clab, 'generic'),
    out.clab= cellstr([repmat('ch',nNewChans,1) int2str((1:nNewChans)')])';
  elseif isequal(opt.clab, 'copy'),
    out.clab= dat.clab;
  else
    out.clab= opt.clab;
  end
elseif ~isdefault.prependix,
%  the following results, e.g., in 'csp 1', but the space is impractical
%  out.clab= cellstr([repmat(opt.prependix,nNewChans,1) ...
%		     int2str((1:nNewChans)')])';
  out.clab= cell(1,nNewChans);
  for ic= 1:nNewChans,
    out.clab{ic}= [opt.prependix int2str(ic)];
  end  
else
  no= NaN*ones(1, nNewChans);
  for ic= 1:nNewChans,
    io= find(A(:,ic)==1);
    if length(io)==1,
      no(ic)= io;
    end
  end
  
  out.clab= cell(1,nNewChans);
  if ~any(isnan(no)),
    for ic= 1:nNewChans,
      out.clab{ic}= [dat.clab{no(ic)} opt.appendix];
    end
  else
    for ic= 1:nNewChans,
      out.clab{ic}= [opt.prependix int2str(ic)];
    end
  end
end

out.origClab= dat.clab;
