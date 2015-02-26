function ax= axis_subplot(m, n, p, mv, mh)
%AXIS_SUBPLOT - Create new axis with better size and location control
%
%Synopsis:
%  H= axis_subplot(M, N, P, <MV, MH>)
%
%Arguments:
% M, N, P  are used like in subplot (but P can also be vector [X Y]),
% MV, MH   specify the horizontal resp. vertical margin
%
% Margins MV, MH are 1 to 3 dimensional row vectors. In the general case, e.g.,
% MH= [L B R], L defines the margin left of the subplot grid, B defines the
% margin between the subplots, and R defines the margin right of the subplot
% grid. The shorter variants are [L B] with R taken =L and [H] with all margins
% L, B, R taking that value. 


if ~exist('mv','var') || isempty(mv), mv= 0; end
if ~exist('mh','var') || isempty(mh), mh= 0; end

if length(mv)==1, mv= [mv mv mv]; end
if length(mv)==2, mv= [mv mv(1)]; end
if length(mh)==1, mh= [mh mh mh]; end
if length(mh)==2, mh= [mh mh(1)]; end

if iscell(p),
  p1= p{1};
  p2= p{2};
  if length(p1)==1 && length(p2)>1,
    p1= p1*ones(1, length(p2));
  elseif length(p2)==1 && length(p1)>1,
    p2= p2*ones(1, length(p1));
  end
  ax= zeros(1, length(p1));
  for ii= 1:length(p1),
    ax(ii)= subplotxl(m, n, [p1(ii) p2(ii)], mv, mh);
  end
  return;
end

if isempty(n),
  mn= m;
  m= floor(sqrt(mn));
  n= ceil(mn/m);
end

pv= ( 0.999 - mv(1) - mv(3) - mv(2)*(m-1) ) / m;
ph= ( 0.999 - mh(1) - mh(3) - mh(2)*(n-1) ) / n;

if length(p)==1,
  iv= m - 1 - floor((p-1)/n);
  ih= mod(p-1, n);
else
  iv= m - p(1);
  ih= p(2) - 1;
end

pos= [mh(1) + ih*(mh(2)+ph),  mv(1) + iv*(mv(2)+pv),  ph,  pv];

ax= axes('position', pos);
