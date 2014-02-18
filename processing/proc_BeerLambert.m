function dat = proc_BeerLambert(dat, varargin)
% PROC_BEERLAMBERT - apply the BeerLambert function, which is useful to analyze
% NIRS data:  relative concentration is calculated as a function of total photon path length
%
% Synopsis:
%   DAT = nirs_LB(DAT, 'Property1',Value1, ...)
%
% Arguments:
%   DAT: data struct with NIRS cnt data split in the x field
%
%   OPT - struct or property/value list of optional properties:
%   'Citation'   - if set, the epsilon (extinction values) is taken from
%                  the specified citation number (see GetExtinctions.m for
%                  details). (default 1 = Gratzer et al)
%   'Epsilon'    - sets extinction coefficients manually (wl1 wl2 vs deoxy
%                  and oxy). In this case, citation is ignored. State in
%                  millimol/liter(?).
%   'Opdist'     - optode (source-detector) distance in cm (default 2.5)
%   'Ival'       - either 'all' (default) or a vector [start end] in samples
%                  specifying the baseline for the LB transformation
%   'DPF'        - differential pathlength factor: probabilistic average
%                  distance travelled by photons, default [5.98 7.15]
%  
% Returns:
%   DAT - updated data struct with oxy/deoxy fields specifying absorption
%         values in mmol/l.
%
%
% See also: nirs_* nirsfile_* GetExtinctions
% 
% Note: Based on the nirX Nilab toolbox functions u_LBG and u_popLBG.

% matthias.treder@tu-berlin.de 2011, mail@aewald.net 2013
% AE: changed channels label from wl1&wl2 to oxa and deoxy.
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert February 2014 (ready for public BBCI toolbox) (jan@mehnert.org)
% ToDo: possibility to define individual baseline; online functionability


props={'Citation'   1             'INT'
        'Opdist'    2.5           'DOUBLE'
        'Ival'      'all'         'CHAR|DOUBLE'
        'DPF'       [5.98 7.15]   'DOUBLE'
        'Epsilon'   []            'DOUBLE'
        'Verbose'   0             'BOOL'};

if nargin==0,
    dat= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

opt_checkProplist(opt, props);
misc_checkType(dat, 'STRUCT');


if strcmp(opt.Ival,'all')
  opt.Ival = [1 size(dat.x,1)];
end

s1=size(dat.x,1);
s2=size(dat.x,2)/2;

wl1 = dat.x(:,1:end/2) + eps;
wl2 = dat.x(:,end/2+1:end) + eps;

%% Get epsilon
if isempty(opt.Epsilon)
  if ~isfield(dat,'wavelengths')
    error('Wavelengths should be given in the .wavelengths field.')
  end
  [ext,nfo] = procutil_getExtinctions(dat.wavelengths,opt.Citation);
  if opt.Verbose, fprintf('Citation: %s\n',nfo), end
  epsilon = ext(:,1:2);
  
  % Divide by 1000 to obtain the required unit
  epsilon = epsilon/1000;
  
else
  epsilon = opt.Epsilon;
end

%% Arrange epsilon so that higher wavelength is on top
[mw,idx] = max(dat.wavelengths);
if idx==2 % higher wavelength is on bottom
  epsilon = flipud(epsilon);
  if opt.Verbose, fprintf('Epsilon matrix was rearranged so that higher WL is on top\n'), end
end

%% Apply Lambert-Beer law
Att_highWL= real(-log10( wl2 ./ ...
    ( repmat(mean(wl2(opt.Ival(1):opt.Ival(2),:),1), [s1,1]))   ));

Att_lowWL= real(-log10( wl1./ ...
    ( repmat(mean(wl1(opt.Ival(1):opt.Ival(2),:),1), [s1,1]))   ));

A=[];
A(:,1)=reshape(Att_highWL,s1*s2,1);
A(:,2)=reshape(Att_lowWL,s1*s2,1);

%----------------------------------
%       3.cc
%----------------------------------
% e=...looks like this
%               oxy-Hb         deoxy-Hb
% higherWL: 830 | e: 0.974       0.693
% lowerWL : 690 | e: 0.35         2.1

e= epsilon/10;

e2=   e.* [opt.DPF' opt.DPF']  .*  opt.Opdist;
c= ( inv(e2)*A'  )';

dat.x = reshape(c(:,1),s1,s2); %in mmol/l
dat.x = [dat.x reshape(c(:,2),s1,s2)]; %in mmol/l

%% Change Channel labels wl1 & wl2 to 'oxy' and 'deoxy'


dat.clab = strrep(dat.clab, 'highWL', 'oxy');
dat.clab = strrep(dat.clab, 'lowWL', 'deoxy');

dat.signal = 'NIRS (oxy, deoxy)';

dat.yUnit = 'mmol/l';