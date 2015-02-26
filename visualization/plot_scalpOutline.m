function H= plot_scalpOutline(mnt, varargin)
%PLOT_SCALPOUTLINE - schematic sketch of the scalp (head, nose, DrawEars)
% and the electrode positions including labels
%
%Synopsis:
% H= PLOT_SCALPOUTLINE(MNT, <OPT>)
%
%Input:
% MNT: mount struct
% OPT: struct or property/value list of optional properties:
%  .ShowLabels           - if true, electrode labels are depicted in circles,
%                          otherwise only the positions are indicated; default 0.
%  .LabelProperties      - text properties of labels (eg 'FontSize', 'Color')
%  .MinorLabelProperties - text properties of long labels (>3 characters)
%  .MarkerProperties     - line/marker properties of electrode position markers
%  .LineProperties       - specify line properties of scalp outline
%  .MarkChannels         - give cell array of channels to be marked
%  .MarkLabelProperties  - same as labelProperties, but only for marked
%                            channels
%  .MarkMarkerProperties - same as markerProperties, but only for marked
%                            channels
%  .DisplayChannels      - channels to display, as a cell array of labels
%                            or alternatively a vector of indices
%  .DrawEars             - if true, draws DrawEars; default 0
%  .Reference            - draws the Reference at 'nose' 'linked_DrawEars'
%                            or 'linked_mastoids'; default none
%  .ReferenceProps       - Reference text properties
%  .H                    - provide axes handle (useful if you want to plot 
%                            the scalp in a subplot)
%
%Output:
% H: struct with handles for the current, the scalp plot, 
%
%Example:
% plot_scalpOutline(mnt,'ShowLabels',1,'LineProperties',{'LineWidth',3},'LabelProperties',{'FontWeight','bold'},'MarkerProperties',{'LineWidth',5,'Color','red'},'DrawEars',1); 
%
% This plots a scalp with DrawEars and red-Colored markers.

% Author: Benjamin Blankertz, Matthias Treder

props = {'DisplayChannels'        []               'DOUBLE|CELL{CHAR}'
         'DrawEars'               0                'BOOL';
         'H'                      struct('ax',NaN) 'STRUCT'
         'LineProperties'         {'LineWidth',3}  'STRUCT|CELL';
         'ShowLabels'             0                'BOOL';
         'LabelProperties'        {'FontSize',8}   'STRUCT|CELL';
         'MinorLabelProperties'   {'FontSize',6}   'STRUCT|CELL';
         'MarkChannels'           []               'DOUBLE|CELL{CHAR}';
         'MarkLabelProperties'    {'FontSize',12,'FontWeight','bold'},    'STRUCT|CELL';
         'MarkMarkerProperties'   {'LineWidth',3,'MarkerSize',22}       'STRUCT|CELL';
         'MarkerProperties'       {'Marker','+','MarkerSize',2,'LineWidth',.2,'MarkerEdgeColor','k'} 'STRUCT|CELL';
         'Offset'                 [0 0]            'DOUBLE[2]';
         'Reference'              0                'BOOL';
         'ReferenceProps'         {'FontSize',8,'FontWeight','bold','BackgroundColor',[.8 .8 .8],'HorizontalAlignment','center','Margin',2}   'STRUCT|CELL';
        };

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if isdefault.H || ~isfield(opt.H, 'ax'),
    opt.H.ax= gca;
end
if isdefault.DisplayChannels
   opt.DisplayChannels= 1:length(mnt.clab);
end

if opt.ShowLabels && isdefault.MarkerProperties,
    opt.MarkerProperties= {'Marker','o','MarkerSize',20,'MarkerEdgeColor','k'};
end

% If no other marker was set, set default marker 'o'
if ~any(strcmpi('Marker',opt.MarkerProperties)),
    opt.MarkerProperties = {opt.MarkerProperties{:},'Marker','o'};
end
% If size is not set, set size to 20
if ~any(strcmpi('MarkerSize',opt.MarkerProperties)),
    opt.MarkerProperties = {opt.MarkerProperties{:},'MarkerSize',20};
end
% If no Color for scalp was set, set default Color black
if ~any(strcmpi('Color',opt.LineProperties)),
    opt.LineProperties = {opt.LineProperties{:}, 'Color','k'};
end
% If channels are given as labels in cells, turn into indices
if iscell(opt.DisplayChannels)
    opt.DisplayChannels = util_chanind(mnt.clab, opt.DisplayChannels);
end

% Normalized units (for positioning, set back later)
oldUnit = get(gcf,'units');
set(gcf,'units','normalized');


% Get axes handle and old position
H= opt.H;
set(gcf,'CurrentAxes',H.ax);
old_pos = get(gca,'position');

% Get coordinates
xe= mnt.x(opt.DisplayChannels)+opt.Offset(1);
ye= mnt.y(opt.DisplayChannels)+opt.Offset(2);

% Plot head
T= linspace(0, 2*pi, 360);
xx= cos(T);
yy= sin(T);
hold on;
H.head= plot(xx+opt.Offset(1), yy+opt.Offset(2), opt.LineProperties{:});

% Plot DrawEars
if opt.DrawEars
    earw = .06; earh = .2;
    H.DrawEars(1)= plot(xx*earw-1-earw+opt.Offset(1), yy*earh+opt.Offset(2), opt.LineProperties{:});
    H.DrawEars(2)= plot(xx*earw+1+earw+opt.Offset(1), yy*earh+opt.Offset(2), opt.LineProperties{:});
end

% Plot nose
nose= [1 1.1 1];
nosi= [86 90 94]+1;
H.nose= plot(nose.*xx(nosi)+opt.Offset(1), nose.*yy(nosi)+opt.Offset(2), opt.LineProperties{:});

% Add Reference
if opt.Reference
    ref = ' REF ';
%    H.ref(1) = text(0,0,ref,opt.ReferenceProps{:});
    switch(opt.Reference),
        case 'nose'
            noseroot = min(nose.*yy(nosi));
            H.ref(1) = text(0,0,ref,opt.ReferenceProps{:},...
                'HorizontalAlignment','Center',...
                'VerticalAlignment','top', 'position',[0 noseroot]);
        case 'linked_DrawEars'
            if exist('earw','var') && exist('earh','var')
                xear = max(get(H.DrawEars(2),'XData'));
                year = -earh/2;
            else xear = max(xx); year=0;
            end
            H.ref(1) = text(-xear,year,ref,opt.ReferenceProps{:},...
                'HorizontalAlignment','right');
            H.ref(2) = text(xear,year,ref,opt.ReferenceProps{:},...
                'HorizontalAlignment','left');
            set(H.ref(:),'VerticalAlignment','middle');
        case 'linked_mastoids'
            if exist('earw','var') && exist('earh','var')
                year = -earh*1.2;
            else year=0;
            end
            H.ref(1) = text(-1,year,ref,opt.ReferenceProps{:},...
                'HorizontalAlignment','right');
            H.ref(2) = text(1,year,ref,opt.ReferenceProps{:},...
                'HorizontalAlignment','left');
            set(H.ref(:),'VerticalAlignment','middle');
            set(H.ref(:),'VerticalAlignment','top');
    end
end

% Add markers & labels
opt.MarkChannels= util_chanind(mnt.clab(opt.DisplayChannels), opt.MarkChannels);
% Plot markers
H.label_markers = [];
for k=1:numel(xe)
    H.label_markers(k)= plot(xe(k), ye(k), 'LineStyle','none', opt.MarkerProperties{:});
end
% Mark marked markers
if ~isempty(opt.MarkChannels)
    set(H.label_markers(opt.MarkChannels), opt.MarkMarkerProperties{:});
end
% Plot labels
if opt.ShowLabels,
  labs= {mnt.clab{opt.DisplayChannels}};
  H.label_text= text(xe, ye, labs);
  set(H.label_text, 'horizontalAlignment','center',opt.LabelProperties{:});
  % Find labels with >3 letters and set their properties
  strLen= cellfun(@length,labs);
  iLong= find(strLen>3);
  set(H.label_text(iLong), opt.MinorLabelProperties{:});
  if ~isempty(opt.MarkChannels),
    set(H.label_text(opt.MarkChannels), opt.MarkLabelProperties{:});
  end
end

%box off;
hold off;
set(H.ax, 'xTick',[], 'yTick',[]); %, 'xColor','w', 'yColor','w');
axis('xy', 'tight', 'equal', 'tight');

% relax XLim, YLim:
xLim= get(H.ax, 'XLim');
yLim= get(H.ax, 'YLim');
set(H.ax, 'XLim',xLim+[-1 1]*0.01*diff(xLim), ...
          'YLim',yLim+[-1 1]*0.01*diff(yLim));

% Set back old figure units
set(gcf,'units',oldUnit);
