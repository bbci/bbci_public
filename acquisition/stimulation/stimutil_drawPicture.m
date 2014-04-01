function HANDLE = stimutil_drawPicture(pic_list, varargin)
 
global BTB
 
props = {'pic_base'    fullfile(BTB.DataDir,'images')  'CHAR'
          'pic_dir'             'stimuli'               'CHAR'
          'image_size'          [.5]                    'DOUBLE[1]'
          'image_pos'           [.5 .5]                 'DOUBLE[2]'
          'image_height_factor' 1                       'DOUBLE[1]'};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);      

%{
if opt.Clf,
  clf;
  set(gcf, 'Position',opt.Position);
  set(gcf, 'ToolBar','none', 'MenuBar','none');
end
%}

pic_dir= fullfile(opt.pic_base, opt.pic_dir);

if ischar(pic_list),
  pic_list= {pic_list};
end

for li= 1:length(pic_list),
  pic{li}= imread([pic_dir filesep pic_list{li}]);
end
sz= size(pic{1});

fp= get(gcf, 'Position');
if length(opt.image_size)==1,
  opt.image_size(2)= opt.image_size(1)/sz(2)*sz(1)/fp(4)*fp(3);
  opt.image_size(2)= opt.image_size(2)*opt.image_height_factor;
end
image_pos= [opt.image_pos-0.5*opt.image_size opt.image_size];

HANDLE.ax= axes('Position',image_pos);
set(HANDLE.ax, 'YDir','reverse', 'Visible','off');
hold on;
for li= 1:length(pic_list),
  HANDLE.image(li)= image(pic{li});
end
axis tight
set([HANDLE.image], 'Visible','off');