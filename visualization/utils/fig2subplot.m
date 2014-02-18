function h = fig2subplot(hfigs, varargin)
%FIGS2SUBPLOT - Arrange figures in subplots within one figure
%
%Description:
% Takes a number of figure handles and arranges them as subplot within a
% single figure. The order of figure handles should correspond to the
% numbering of the axes in the subplot.
%
%Synposis:
% H = figs2subplot(HFIGS, <OPT>)
%
%Input:
% HFIGS: a vector of figure handles
% OPT: struct or property/value list of optional properties. It can be used
% in four ways to generate a figure.
%   (1) Give the number of rows and columns, a subplots with size equal to
%       the maximum height and width of the figures are created. The sizes 
%       of the figures are preserved
%    .RowsCols    - the number of rows and columns, eg. [2 1]
%    .InnerMargin - minimum margin between plots in pixels [horizontal vertical]
%    .OuterMargin - outer margins [left right top bottom] of the whole plot in
%                   pixels
%   (2) Provide a predefined subplot figure
%    .HMain - handle of a predefined subplot figure. The positions of
%             the subplots will be used to place the figures.
%   (3) Make a subplot of rows and columns
%    .Rows   - normalized sizes of the rows (e.g., [.1 .3 .4])
%    .Cols   - normalized sizes of the columns. If there is space over,
%              rows and columns are evenly spread.
%    .Margin - outer margins [left right top bottom] of the whole plot
%   (4) Make an arbitrary subplot
%    .Positions - a n x 4 matrix of normalized axes position data 
%                 [left bottom width height]
%
% If none of these arguments is set, a default n x 1 subplot is created, 
% where n is the number of figure handles
%
% Other options
%  .DeleteFigs - the original figures are deleted after they were copied
%                into the new figure
%  .Label      - automatically label the subfigures by running numbers or
%                letters. Specify label type by a string, eg. '(a)'
%                (for (a) (b), etc), 'a', 'a.', capital letters, or
%                numerical variants '(1)' '1', '1.'  (default []). 
%                Alternatively, you can provide a cell array of
%                strings representing custom labels.
%  .LabelPos   - positions of the labels, the values correspond to the
%                values used for legend positions (default 'NorthWest')
%  .LabelOpt   - formatting options for label as cell array 
%                (default {'FontSize' 12 'FontWeight' 'bold'})
%                 
%
%Output:
% H: Handle to the new subplot figure and its children
% .axes     - axes wherein the new subplots are placed
% .children - the copied graphics objects
%
%Example: (4 figures with four different colormaps arranged in a 2x2 subplot)
% close all
% [X,Y,Z] = peaks(30); % fig 1
% surf(X,Y,Z), colormap jet
% figure,pcolor(rand(20)) % fig 2
% colormap copper
% figure,contourf(peaks(40),10),colormap winter % fig 3
% figure,plot(sin(1:.1:pi)'*[1:22],'LineWidth',3); % fig 4
% H = fig2subplot([1:4],'RowsCols',[2 2],'label','(a)')

% Author(s): Matthias Treder, Benjamin Blankertz Nov 2009
% Aug 2010: Added automatic labeling (mt)

props = {'HMain',           [],                     'DOUBLE';
         'RowsCols',        [],                     'DOUBLE[2]';
         'Rows',            [],                     'DOUBLE[3]';
         'Cols',            [],                     'DOUBLE[3]';
         'InnerMargin',     [0 0],                  'DOUBLE[2]';
         'OuterMargin',     [10 10 10 10],          'DOUBLE[4]';
         'Margin',          [.05 .05 .05 .05],      'DOUBLE[4]';
         'Positions',       [],                     'DOUBLE[4]';
         'DeleteFigs',      0,                      'BOOL';
         'Label',           [],                     'CHAR';
         'LabelPos',        'northwest',            'CHAR';
         'LabelOpt',        {'FontSize', 14, 'FontWeight', 'bold'},   'STRUCT|CELL'
         };

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if isdefault.HMain && isdefault.RowsCols && isdefault.Rows && ... 
    isdefault.Positions
  % Nothing was set
  opt.RowsCols = [numel(hfigs) 1];
end

% Prepare labels
if ~isempty(opt.Label) && ~iscell(opt.Label)
  ll = cell(1,numel(hfigs));
  for ii=1:numel(hfigs)
    switch(opt.Label)
      case '(a)', ll{ii} = ['(' char(96+ii) ')'];
      case '(A)', ll{ii} = ['(' char(64+ii) ')'];
      case 'a',   ll{ii} = char(96+ii);
      case 'A',   ll{ii} = char(64+ii);
      case 'a.',  ll{ii} = [char(96+ii) '.'];
      case 'A.',  ll{ii} = [char(64+ii) '.'];
      case '(1)', ll{ii} = ['(' num2str(ii) ')'];
      case '1',   ll{ii} = num2str(ii);
      case '1.',  ll{ii} = [num2str(ii) '.'];
    end
  end
  opt.Label = ll;
end

% Prepare the axes of the new figure
h = struct('main',[],'axes',[]);
h.cmap_start_idx = []; % denotes the start indices of the separate colormaps in the compound colormap
if isempty(opt.HMain)
    % No figure yet, make one
    h.main = figure;
    if ~isempty(opt.RowsCols)
        % option 1
        % Get height and width in px of figures
        set(hfigs,'units','pixels');
        pos = get(hfigs,'position');
        pos = cat(1,pos{:});
        widmat=[];heimat=[]; % width and height matrix
        idx=1;
        for rr = 1:opt.RowsCols(1)  % all rows
          for cc=1:opt.RowsCols(2)  % all cols
            if numel(hfigs)>=idx
              widmat(rr,cc) = pos(idx,3); heimat(rr,cc)=pos(idx,4);
            else
              widmat(rr,cc) = 0; heimat(rr,cc)=0;
            end
            idx=idx+1;
          end
        end
        rows = max(heimat,[],2);
        cols = max(widmat,[],1);
        % Set figure size
        figwid = opt.OuterMargin(1)+opt.OuterMargin(2)+opt.InnerMargin(1)*(numel(cols)-1);
        fighei = opt.OuterMargin(3)+opt.OuterMargin(4)+opt.InnerMargin(2)*(numel(rows)-1);
        figwid = figwid + sum(cols);
        fighei = fighei + sum(rows);
        set(h.main,'units','pixels');
        mainpos = get(h.main,'position');
        set(h.main,'position',[mainpos(1:2) figwid fighei]);
        % Get back to normalized units
        set(h.main,'units','normalized');
        widmat = widmat/figwid;
        cols=cols/figwid;
        heimat = heimat/fighei;
        rows=rows/fighei;
        opt.OuterMargin(1) = opt.OuterMargin(1)/figwid;
        opt.OuterMargin(2) = opt.OuterMargin(2)/fighei;
        opt.OuterMargin(3) = opt.OuterMargin(3)/figwid;
        opt.OuterMargin(4) = opt.OuterMargin(4)/fighei;
        opt.InnerMargin(1) = opt.InnerMargin(1)/figwid;
        opt.InnerMargin(2) = opt.InnerMargin(2)/fighei;
        % Place new axes
        h.axes = []; hidx = 1;
        rowStart = 1-opt.OuterMargin(3)-rows(1); % start at top 
        for rr = 1:numel(rows)
            colStart = opt.OuterMargin(1); % start left
            for cc = 1:numel(cols)
                h.axes(hidx) = axes('position', ...
                    [colStart rowStart widmat(rr,cc) heimat(rr,cc)], ...
                    'parent',h.main,'visible','off');
                axis off;
                colStart = colStart + cols(cc) + opt.InnerMargin(1);
                hidx = hidx+1;
                if hidx > numel(hfigs); break;end;
            end
            if rr<numel(rows)
                rowStart = rowStart - opt.InnerMargin(2) - rows(rr+1);
            end
            if hidx > numel(hfigs); break;end;  % break when rows*cols > number of figures
            numel(hfigs)
        end
    elseif isempty(opt.Positions)
        % option 2
        % Inner space left for rows and cols
        colSpace = 1-opt.Margin(1)-opt.Margin(2);
        rowSpace = 1-opt.Margin(3)-opt.Margin(4);
        % Calculate space left over between axes
        rowOver = (rowSpace-sum(opt.Rows)) / (numel(opt.Rows)-1);
        colOver = (colSpace-sum(opt.Cols)) / (numel(opt.Cols)-1);
        h.axes = []; hidx = 1;
        rowStart = 1-opt.Margin(3)-opt.Rows(1); % start at top 
        for rr = 1:numel(opt.Rows)
            colStart = opt.Margin(1); % start left
            for cc = 1:numel(opt.Cols)
                h.axes(hidx) = axes('position', ...
                    [colStart rowStart opt.Cols(cc) opt.Rows(rr)], ...
                    'parent',h.main,'visible','off');
                axis off;
                colStart = colStart + opt.Cols(cc) + colOver;
                hidx = hidx+1;
            end
            if rr<numel(opt.Rows)
                rowStart = rowStart - rowOver - opt.Rows(rr+1);
            end
        end
    else
        % option 3
        for ii=1:size(opt.Positions,1)
            h.axes(ii) = axes('position',opt.Positions(ii,:),'parent',h.main);
        end
    end
else
    % Option 1, nothing much to do ..
    h.main = opt.HMain;   % figure
    h.axes = findobj(h.main,'Type','Axes');   % its children axes
    h.axes = flipud(h.axes);  % to start with ax 1
end

% Copy colormap from first figure to the new one
set(h.main, 'Colormap', get(hfigs(1),'Colormap'));

% Traverse old figures and place them in the new plot
for ii=1:numel(hfigs)
  % Save connection between Colorbars and their Parent Axes
  hcb= findobj(hfigs(ii), 'Tag','Colorbar');
  for jj= 1:length(hcb),
    hhcb= handle(hcb(jj));
    if isfield(hhcb,'axes')
      hpa= double(hhcb.axes); % that's the axes the colorbar is refering to
    else
      hpa = double(hhcb);
    end
    if ~isempty(hpa),
      ud= get(hcb(jj), 'UserData');
      ud.ParentAxis= hpa;
      set(hcb(jj), 'UserData',ud);
    end
  end
  
  % Check if colormap's different
  newColmap = get(hfigs(ii),'colormap');
  if ii>1 && ~isequal(newColmap,get(h.main,'colormap'))
     acm = fig_addColormap(newColmap,'colormap');
  end
  % Copy all objects from old fig to new
  % use findall not findobj to also find hidden objects like fake axes
  % produced by axespos()
  oldax = findall(hfigs(ii),'Type','Axes'); 
  
  % Sometimes colors are clipped in the original images (because colors
  % fall out of CLim color limits). To ensure clipping is preserved after a
  % new colorbar is being added, these values should be set to the CLim
  % limits.
  for oo=1:numel(oldax)
    cLim = get(oldax(oo),'CLim');
    child = get(oldax(oo),'Children');
    % Patch objects include scalp maps
    pat = findobj(child,'Type','patch');
    for pp=1:numel(pat)
      cd = get(pat(pp),'Cdata');
      cd(cd(:)<cLim(1))=cLim(1);   % Lower than min is set to min
      cd(cd(:)>cLim(2))=cLim(2);   % Greater than max is set to max
      set(pat(pp),'Cdata',cd);    
    end
    % Image objects include time-frequency plots
    im = findobj(child,'Type','image','Tag','');
    for jj=1:numel(im)
      cd = get(im(jj),'Cdata');
      cd(cd(:)<cLim(1))=cLim(1);   % Lower than min is set to min
      cd(cd(:)>cLim(2))=cLim(2);   % Greater than max is set to max
      set(im(jj),'Cdata',cd);
    end
  end
  
  % Copy objects from old to new figure
  newax = copyobj(oldax,h.main); % Copy figure
  % Get position of subplot and positions of old plot
  set(hfigs(ii),'units','normalized');
  oldpos = get(oldax,'position');
  subpos = get(h.axes(ii),'position');
  % Make new positions
  if ~iscell(oldpos), oldpos = {oldpos}; end;
  for kk=1:numel(oldpos)
    oo = oldpos{kk};  % copy into oo for convenience
    newl = [subpos(1)+subpos(3)*oo(1) subpos(2)+subpos(4)*oo(2) ...
        subpos(3)*oo(3) subpos(4)*oo(4)];
    set(newax(kk),'Position',newl);
  end
  % Adjust colormap if necessary
  if  ii>1 && ~isequal(get(hfigs(ii),'colormap'),get(h.main,'colormap')),
    newcb= findobj(newax, 'Tag', 'Colorbar');
    newaxes= setdiff(newax, newcb,'legacy');
    visutil_acmAdaptCLim(acm, newaxes);
    % Adjust the displaying of the new colorbar [wieder einkommentiert]
    scnew = size(get(hfigs(ii),'colormap'),1);
    sc = size(colormap,1);
    for kk=1:numel(newcb)
%      set(get(newcb(kk),'Children'),'CData',(sc-scnew+1:sc)');
      newcb_ch= get(newcb(kk),'Children');
      newcb_ch= newcb_ch(~ismember(get(newcb_ch,'Type'),{'text'},'legacy'));
      set(newcb_ch,'CData',(sc-acm.nColors+1:sc)');
    end
%     % Adjust graphic objects whereby color mapping is direct
%     % (ie not controlled via clim)
%     axes_direct = findall(newaxes,'CDataMapping','direct');
%     for kk=1:numel(axes_direct)
%       cdata = get(axes_direct(kk),'CData');
%       set(axes_direct(kk),'CData',cdata+abs(diff([size(colormap,1) acm.nColors])));
%     end
  end   
  % Place label
  if ~isempty(opt.Label)
    set(gcf,'CurrentAxes',h.axes(ii))
    xl = get(gca,'XLim');
    yl = get(gca,'YLim');
    switch(lower(opt.LabelPos))
      case 'northwest'
        h.label(ii) = text(xl(1),yl(2),opt.Label{ii}, ...
          'VerticalAlignment','top','HorizontalAlignment','left', ...
          opt.LabelOpt{:});
      case 'north'
        h.label(ii) = text(mean(xl),yl(2),opt.Label{ii}, ...
          'VerticalAlignment','top','HorizontalAlignment','center', ...
          opt.LabelOpt{:});
      case 'northeast'
        h.label(ii) = text(xl(2),yl(2),opt.Label{ii}, ...
          'VerticalAlignment','top','HorizontalAlignment','right', ...
          opt.LabelOpt{:});
      case 'west'
        h.label(ii) = text(xl(1),mean(yl),opt.Label{ii}, ...
          'VerticalAlignment','middle','HorizontalAlignment','left', ...
          opt.LabelOpt{:});
      case 'east'
        h.label(ii) = text(xl(2),mean(yl),opt.Label{ii}, ...
          'VerticalAlignment','middle','HorizontalAlignment','left', ...
          opt.LabelOpt{:});
      case 'southwest'
        h.label(ii) = text(xl(1),yl(1),opt.Label{ii}, ...
          'VerticalAlignment','bottom','HorizontalAlignment','left', ...
          opt.LabelOpt{:});
      case 'south'
        h.label(ii) = text(mean(xl),yl(1),opt.Label{ii}, ...
          'VerticalAlignment','bottom','HorizontalAlignment','center', ...
          opt.LabelOpt{:});
      case 'southeast'
        h.label(ii) = text(xl(2),yl(1),opt.Label{ii}, ...
          'VerticalAlignment','bottom','HorizontalAlignment','right', ...
          opt.LabelOpt{:});
    end
  end
end

% delete(h.axes)  % these axes were only placeholders for the new data
set(h.axes,'visible','off')
% h.axes = get(gcf,'Children');
h.children = setdiff(get(gcf,'Children'),h.axes,'legacy'); % Get all children except for the new axes

if opt.DeleteFigs
    delete(hfigs);
end
