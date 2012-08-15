function fv= proc_r_square(fv, varargin)
%PROC_R_SQUARE - computes r^2 values (measeure for discriminance)
%
%Synopsis:
% fv_rsqu= proc_r_square(fv, <opt>)
%
%Arguments:
%   fv  - data structure of feature vectors
%   fv2 - (optional) data structure of feature vectors. If fv2 is
%             specified, fv and fv2 must have only a single class: The
%             function then computes the discriminability between the two
%             feature vectors.
%   opt - struct or property/value list of optional properties
%     .tolerateNans: observations with NaN value are skipped
%            (nanmean/nanstd are used instead of mean/std)
%     .valueForConst: constant feauture dimensions are assigned this
%            value. Default: NaN.
%     .multiclassPolicy: possible options: 'pairwise' (default), 
%           all-against-last', 'each-against-rest', or provide specified
%           pairs as an [nPairs x 2] sized matrix. 
%
%Returns:
%   fv_rsqu - data structute of r^2 values (one sample only)
%
%Description:
% Computes the r^2 value for each feature. The r^2 value is a measure
% of how much variance of the joint distribution can be explained by
% class membership.
%
% SEE  proc_t_scaled, proc_r_values

% 03-03 Benjamin Blankertz
fv = misc_history(fv);


if length(varargin)>0 & isstruct(varargin{1}),
  fv2= varargin{1};
  varargin= varargin(2:end);
  if size(fv.y,1)*size(fv2.y,1)>1,
    error('when using 2 data sets both may only contain 1 single class');
  end
  if strcmp(fv.className{1}, fv2.className{1}),
    fv2.className{1}= strcat(fv2.className{1}, '2');
  end
  fv= proc_appendEpochs(fv, fv2);
  clear fv2;
end

fv= proc_r_values(fv, varargin{:});
fv.x= fv.x.^2;
for cc= 1:length(fv.className),
  fv.className{cc}= ['r^2' fv.className{cc}(2:end)];
end
fv.yUnit= 'r^2';



return


%% function as adapted from what Gerwin Schalk supplied
%% (variance is normalized by N not N-1)
%
%c1= find(fv.y(1,:));
%c2= find(fv.y(2,:));
%lp= length(c1);
%lq= length(c2);
%sz= size(fv.x);
%rsqu= zeros(sz(1:2));
%for ti= 1:sz(1),
%  for ci= 1:sz(2),
%    p= fv.x(ti,ci,c1);
%    q= fv.x(ti,ci,c2);
%    sp= sum(p, 3);
%    sq= sum(q, 3);
%    g= (sp+sq)^2 / (lp+lq);
%    rsqu(ti, ci)= ( sp^2/lp + sq^2/lq - g ) / ( sum(p.^2) + sum(q.^2) - g );
%  end
%end
