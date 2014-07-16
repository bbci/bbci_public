function HANDLE= stimutil_showDescription(desc, varargin)
%STIMUTIL_SHOWDESCRIPTION - Show a Description and Wait
%
%Synopsis:
% HANDLE= stimutil_showDescription(DESC, <OPT>)
%
%Arguments:
% DESC: String or cell array of strings.
% OPT: struct or property/value list of optional arguments:
% 'HandleMsg': Handle to text object which is used to display the countdown
%    message. If empty a new object is generated. Default [].
% 'HandleBackground': Handle to axis object on which the message should be
%    rendered. If empty a new object is generated. Default [].
% 'DescTextspec': Cell array. Text object specifications for description
%   text object. Default: {'FontSize',0.05, 'Color',[0 0 0]})
% 'Waitfor': Stop criterium. Possible values are numeric values specifying
%   the time to wait in seconds, the string 'key' which means waiting
%   until the experimentor hits a key in the matlab console or a string
%   or cell arrow of strings which is interpreted as marker descriptions
%   for which the EEG is scanned then (e.g. 'R*' waits until some response
%   marker is acquired).
%   Use value 0 for no waiting.
% 'delete': Delete graphic objects at the end. Default 1, except for
%   opt.Waitfor=0.
%
%Returns:
% HANDLE: Struct of handles to graphical objects (only available for
%    opt.Delete=0).
%
%Example:
% shows the message 'Hello World' for 5 seconds.
% stimutil_showDescription('Hello World', 'waitfor', 5)

% blanker@cs.tu-berlin.de, Jul-2007

global BTB

props= {'Clf'               0                               'BOOL'
        'HandleBackground' []                              'HANDLE'
        'DescMaxsize'      [0.9 0.8]                       'DOUBLE[2]'
        'DescTextspec'     {   'FontSize',0.05, ...
                                'Color',.0*[1 1 1]}         'CELL|STRUCT'
        'DescPos'          [0.5 0.5]                       'DOUBLE[2]'
        'DescBoxgap'        0.05                           'DOUBLE[1]'
        'Delete'            1                               'BOOL'       
        'Position'          BTB.Acq.Geometry                       'DOUBLE[4]'
        'Waitfor'           'R*'                            'DOUBLE|CHAR'
        'WaitforMsg'       'Press <ENTER> to continue: '   'CHAR'
        'Frame'             1                               '!BOOL'};

%props_marker= stimutil_waitForMarker;

if nargin==0,
%  HANDLE = opt_catProps(props,props_marker);
  HANDLE = props;
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

%opt_marker= opt_substruct(opt, props_marker(:,1));

if isequal(opt.Waitfor, 0),
  opt.Delete= 0;
end

HANDLE= [];
if opt.Clf,
  clf;
  set(gcf, 'Position',opt.Position);
  set(gcf, 'ToolBar','none', 'MenuBar','none');
end

if isempty(get(gcf, 'Children')),
  memo.axis= [];
else
  memo.axis= gca;
end
h.axis= axes('Position',[0 0 1 1]);
set(h.axis, 'XLim',[0 1], 'YLim',[0 1], 'Visible','off');

if iscell(desc),
  %% Description has linebreaks:
  %% Choose size of the description box by trial and error
  col_background= get(gcf, 'Color');
  factor= 1;
  too_small= 1;
  nLines= length(desc);
  nChars= max(cellfun(@length,desc));
  while too_small,
    desc_fontsize= factor * min( opt.DescMaxsize./[nChars nLines] );
    ht= text(opt.DescPos(1), opt.DescPos(2), desc);
    set(ht, 'FontUnits','normalized', 'FontSize',desc_fontsize, ...
            'Color',col_background, 'HorizontalAli','center');
    drawnow;
    rect= get(ht, 'Extent');
    too_small= rect(3)<opt.DescMaxsize(1) & rect(4)<opt.DescMaxsize(2);
    if too_small,
      factor= factor*1.1;
    end
    delete(ht);
  end
  factor= factor/1.1;
  %% render description text
  desc_fontsize= factor * min( opt.DescMaxsize./[nChars nLines] );
  h.text= text(opt.DescPos(1), opt.DescPos(2), desc);
  set(h.text, opt.DescTextspec{:}, 'HorizontalAli','center', ...
              'FontUnits','normalized', 'FontSize',desc_fontsize);
else
  %% Description is given as plain string:
  %% Determine number of characters per row
  textfield_width= opt.DescMaxsize(1);
  textfield_height= opt.DescMaxsize(2);
  ht= text(0, 0, {'MMMMMMM','MMMMMMM','MMMMMMM','MMMMMMM','MMMMMMM'});
  set(ht, 'FontName','Courier New', 'FontUnits','normalized', ...
          opt.DescTextspec{:});
  rect= get(ht, 'Extent');
  char_width= rect(3)/7;
  linespacing= rect(4)/5;
  char_height= linespacing*0.85;
  textfield_nLines= floor((textfield_height-2*char_height)/linespacing)+2;
  textfield_nChars= floor(textfield_width/char_width);
  delete(ht);
  h.text= text(opt.DescPos(1), opt.DescPos(2), {' '});
  set(h.text, 'HorizontalAli','center', 'FontUnits','normalized', ...
              opt.DescTextspec{:});

  %% Determine linebreaking.
  writ= [desc ' '];
  iBreaks= find(writ==' ');
  ll= 0;
  clear textstr;
  while length(iBreaks)>0,
    ll= ll+1;
    linebreak= iBreaks(max(find(iBreaks<textfield_nChars)));
    if isempty(linebreak),
      %% word too long: insert hyphenation
      linebreak= textfield_nChars;
      writ= [writ(1:linebreak-1) '-' writ(linebreak:end)];
    end
    textstr{ll}= writ(1:linebreak);
    writ(1:linebreak)= [];
    iBreaks= find(writ==' ');
  end
  textstr{end}= textstr{end}(1:end-1);
  textstr= textstr(max(1,end-textfield_nLines+1):end);
  set(h.text, 'String',textstr);
end

drawnow;
rect= get(h.text, 'Extent');
set(h.text, 'Position',[rect(1) opt.DescPos(2), 0]);
set(h.text, 'HorizontalAli','left');

%% render description frame
if opt.Frame
  h.frame= line([rect(1)+rect(3) rect(1)+rect(3) rect(1) rect(1); ...
                 rect(1)+rect(3) rect(1) rect(1) rect(1)+rect(3)] + ...
                opt.DescBoxgap*[1 1 -1 -1; 1 -1 -1 1], [rect(2)+rect(4) ...
                      rect(2) rect(2) rect(2)+rect(4); rect(2) rect(2) ...
                      rect(2)+rect(4) rect(2)+rect(4)] + opt.DescBoxgap*[1 ...
                      -1 -1 1; -1 -1 1 1]);
  set(h.frame, 'LineWidth',2, 'Color',[0 0 0]);
end

if ~isempty(opt.Waitfor),
  if isnumeric(opt.Waitfor),
    pause(opt.Waitfor),
  elseif isequal(opt.Waitfor, 'key'),
    fprintf(opt.WaitforMsg);
    pause;
    fprintf('\n');
  else
    stimutil_waitForMarker(opt.Waitfor);
  end
end

if isequal(opt.Delete, 'fig'),
  close;
elseif opt.Delete,
  delete(h.axis);
  drawnow;
else
  if ~isempty(memo.axis),
    axes(memo.axis);
  end
  if nargout>0,
    HANDLE= h;
  end
end
