function util_printFigure(file, varargin)
%UTIL_PRINTFIGURE - Save the current Matlab figure
%
%Synopsis:
% util_printFigure(FILE, <OPT>)
% util_printFigure(FILE, PAPERSIZE, <OPT>)
%
%Arguments:
% FILE:     CHAR        Name of the output file (without extension).
%                       If the filename is relative, BTB_FIG_DIR 
%                       (global var) is prepended.
% PAPERSIZE: see OPT.PaperSize
% OPT: struct or propertyvalue list of optional properties
%  .PaperSize: [X Y] size of the output in centimeters, or 'maxAspect' or 'auto'.
%  .Device:  Matlab driver used for printing, e.g.
%     ps, eps, epsc, epsc2 (default), jpeg, tiff, png
%  .Format: eps or pdf. If OPT.Format is 'pdf', then 'epstopdf' is used
%     to convert the output file to PDF format
%     NEW FEATURE: 'format' may be 'svg'. This ignores 'device' and 'paperSize'
%  .Append: append current figure as new page in existing file
%  .Renderer: how the figure is rendered to a file, 'painters' (default)
%     produces vector images, 'zbuffer' and 'opengl' produce bitmaps

global BTB
BTB= opt_setDefaults(BTB, {'FigDir',  ''  'CHAR'});

props = {   
        'PaperSize'       'auto'        '!CHAR(auto maxAspect)|!DOUBLE[- -]';
        'Format'          'eps'         '!CHAR(eps pdf svg epspdf png)';
        'Device'          'epsc2'       '!CHAR';
        'Folder'          ''            'CHAR';
        'Prefix'          ''            'CHAR';
        'Resolution'      []            'DOUBLE[1]';
        'Renderer'        'painters'    '!CHAR(painters zbuffer opengl)';
        'Embed'           1             '!BOOL';
        'Append'          []            'CHAR';
        'FigNos'          []            'INT';
         };

if isnumeric(varargin{1}) || isequal(varargin{1}, 'maxAspect'),
  opt= opt_proplistToStruct(varargin{2:end});
  opt.PaperSize= varargin{1};
else
  opt= opt_proplistToStruct(varargin{:});
end

[opt,isdefault] = opt_setDefaults(opt, props, 1);
misc_checkType(file,'!CHAR');

set(gcf,'Renderer',opt.Renderer);
                   
if ~isempty(opt.FigNos)
  for ff= 1:length(opt.FigNos),
    figure(opt.FigNos(ff));
    if length(opt.FigNos)>1,
      save_name= [file int2str(ff)];
    else
      save_name= file;
    end
    printFigure(save_name, rmfield(opt, 'fig_nos'));
  end
  return;
end

if ischar(opt.PaperSize) && strcmp(opt.PaperSize,'maxAspect'),
  set(gcf, 'paperOrientation','landscape', 'paperType','A4', ...
           'paperUnits','inches', ...
           'paperPosition',[0.25 0.97363 10.5 6.5527]);
elseif ischar(opt.PaperSize) && strcmp(opt.PaperSize,'auto'),
  set(gcf, 'PaperType','A4', ...
           'PaperPositionMode','auto');
else
  if length(opt.PaperSize)==2, opt.PaperSize= [0 0 opt.PaperSize]; end
  set(gcf, 'paperOrientation','portrait', 'paperType','A4', ...
           'paperUnits','centimeters', 'paperPosition',opt.PaperSize);
end

if fileutil_isAbsolutePath(file),
  fullName= file;
else
  fullName= fullfile(opt.Folder, [opt.Prefix file]);
  if ~fileutil_isAbsolutePath(fullName) && exist(BTB.FigDir, 'dir'),
    fullName= fullfile(BTB.FigDir, fullName);
  end
end

[filepath, filename]= fileparts(fullName); 
if ~exist(filepath, 'dir'),
  [parentdir, newdir]= fileparts(filepath);
  [status, msg]= mkdir(parentdir, newdir);
  if status~=1,
    error(msg);
  end
%  if isunix,
%    unix(sprintf('chmod a-rwx,ug+rwx %s', filepath));
%  end
  fprintf('new directory <%s%s%s> created\n', parentdir, filesep, newdir);
end

if strcmpi(opt.Format, 'SVG'),
  if ~exist('', 'file'),
    addpath([BTB.Dir 'import/plot2svg']);
  end
  plot2svg([fullName '.svg']);
  return;
end

if isempty(opt.Append)
    if isempty(opt.Resolution),
      print(['-d' opt.Device], fullName);
    else
      print(['-d' opt.Device], ['-r' int2str(opt.Resolution)], fullName);
    end
else
    % Append figure to existing file
    if isempty(opt.Resolution),
      print(['-d' opt.Device],'-append', fullName);
    else
      print(['-d' opt.Device],'-append', ['-r' int2str(opt.Resolution)], fullName);
    end
end

if strcmpi(opt.Format, 'PDF') || strcmpi(opt.Format, 'EPSPDF'),
  if ~strncmp('eps', opt.Device, 3),
    error('For output in PDF format, OPT.Device must be eps*');
  end
  cmd= sprintf('cd %s; epstopdf --embed %s.eps', filepath, filename);
  util_unixCmd(cmd, 'could not convert EPS to PDF');
  if strcmpi(opt.Format, 'PDF'),
    cmd= sprintf('cd %s; rm %s.eps', filepath, filename);
    util_unixCmd(cmd, 'could not remove EPS');
  end
end
