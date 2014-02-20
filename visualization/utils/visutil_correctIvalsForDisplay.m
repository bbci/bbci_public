function ival= visutil_correctIvalsForDisplay(ival, varargin)
%VISUTIL_CORRECTIVALSFORDISPLAY - Shift interval time points such that no
% part of the interval is obscured by bounding boxes when drawing

if length(varargin)==1,
  varargin= {'Fs', varargin{1}};
end

misc_checkType(ival,'DOUBLE[- 2]');

props= {'Fs'                       100       'DOUBLE[1]'
        'Sort'                      1        'BOOL'
        'OnlyPointIntervals'        0        'BOOL'   };

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if opt.Sort,
  [~,si]= sort(ival(:,1));
  ival= ival(si,:);
end

if opt.OnlyPointIntervals,
  to_be_checked= find(diff(ival, 1, 2)==0)';
else
  to_be_checked= 1:size(ival, 1);
end

for ii= to_be_checked,
  if ii==1 || ival(ii-1,2)<ival(ii,1),
    ival(ii,1)= ival(ii,1) - 1000/opt.Fs/2;
  end
  if ii==size(ival,1) || ival(ii,2)<ival(ii+1,2),
    ival(ii,2)= ival(ii,2) + 1000/opt.Fs/2;
  end
end
