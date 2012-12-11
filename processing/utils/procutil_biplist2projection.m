function proj= procutil_biplist2projection(clab, bip_list, varargin)
% PROCUTIL_BIPLIST2PROJECTION -  %%%
%
%Usage:
% proj = procutil_biplist2projection(clab, bip_list, <OPT>)
%
% ***** TODO
%Arguments:
% CLAB      -  data structure of continuous or epoched data
% FREQ     -  Fourier center frequencies of the wavelets (eg [1:100] Hz)
% OPT - struct or property/value list of optional properties:
% 'Mother' -  mother wavelet (default 'morlet'). Morlet is currently the
%             only implemented wavelet.
% 'w0'    -   unitless frequency constant defining the trade-off between
%             frequency resolution and time resolution. For Morlet
%             wavelets, it sets the width of the Gaussian window. (default 7)
%
%Returns:
% DAT    -    updated data structure with a higher dimension.
%             For continuous data, the dimensions correspond to 
%             time x frequency x channels. For epoched data, time x
%             frequency x channels x epochs.
% INFO   -    struct with the following fields:
% .fun       - wavelet functions (in Fourier domain)
% .length    - length of each wavelet in time samples
% .freq      - wavelet center frequencies
%
% See also PROC_SPECTROGRAM.
              
props = {'DeletePolicy',             'auto',        '!CHAR';
         'LabelPolicy',              'auto',        '!CHAR'
         };
       
if nargin==0,
  proj= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(clab,'CELL|STRUCT');
misc_checkType(bip_list,'');


if isfield(clab, 'clab'),  %% if first argument is, e.g.,  cnt or epo struct
  clab= clab.clab;
end

for bb= 1:length(bip_list),
  bip= bip_list{bb};
  proj(bb).chan= bip{1};
  proj(bb).filter= zeros(length(clab), 1);
  proj(bb).filter(util_chanind(clab, bip{1:2}))= [1 -1];
  if length(bip)>2,
    proj(bb).new_clab= bip{3};
  else
    switch(lower(opt.LabelPolicy)),
     case 'auto',
      if strcmpi(bip{2}(end-2:end), 'ref'),
        proj(bb).new_clab= clab{proj(bb).cidx};
      elseif ismember(bip{1}(end), 'pn') & ismember(bip{2}(end),'pn') | ...
             ismember(bip{1}(end), 'lr') & ismember(bip{2}(end),'lr'),
        proj(bb).new_clab= bip{1}(1:end-1);
      end
     case 'deletelastchar',
      proj(bb).new_clab= bip{1}(1:end-1);
     case 'firstlabel',
      proj(bb).new_clab= clab{proj(bb).cidx};
     otherwise,
      error('choice for OPT.LabelPolicy unknown');
    end
  end
  switch(lower(opt.DeletePolicy)),
   case 'auto',
    if numel(bip{2})>2 && strcmpi(bip{2}(end-2:end), 'ref') | ...
          (ismember(bip{1}(end), 'pn') & ismember(bip{2}(end),'pn')) | ...,
          (ismember(bip{1}(end), 'lr') & ismember(bip{2}(end),'lr')),
      proj(bb).rm_clab= bip{2};
    else
      proj(bb).rm_clab= {};
    end
   case 'second',
    proj(bb).rm_clab= bip{2};
   case 'never',
    proj(bb).rm_clab= {};
   otherwise,
    error('choice for OPT.DeletePolicy unknown');
  end
end

[proj.clab]= deal(clab);
