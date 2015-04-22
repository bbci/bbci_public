function image_localColormap(C, cmap, varargin)
%IMAGE_LOCALCOLORMAP - Display image without using the figure's colormap
%
%Description:
% One problem in Matlab's graphics is that all subplots of one figure
% all share the same colormap. This function allows one work-around by
% displaying an image without using the figure's colormap. To this end
% each rectangular of the image is plotted using the function FILL,
% which can be quite time consuming.
%
%Synopsis:
% image_localColormap(C, CMAP, <OPT>)
%
%Input:
% C:    Matrix to be displayed
% CMAP: Colormap to be used, [nColors 3]-sized array of RGB-coded colors.
% OPT:  Property/value list or struct of optional properties:
%  .CLim      - The values of the color matrix C, whose values are in the
%               range CLim= [Cmin, Cmax] are mapped to color indices in the
%               range [1 nColors], indexing into the specified colormap CMAP.
%               When .CLim is set to 'auto' (default) the range [Cmin Cmax]
%               is chosen tight as [min(C(:)) max(C(:))].
%  .EdgeColor - Specifies the edge color of the rectangulars,
%               default 'none'.
%  .Optimize  - Can be 'rows' or 'columns' and determines in which
%               direction consequtive entries in the color matrix that
%               index the same color are represented by one patch.
%               Note: this does not change the look of the image, it just
%               optimizes the internal representation by having (potentially)
%               less paches.
%
%Example:
% clf; colormap default;
% subplot(1,2,1); imagesc(toeplitz(1:10));
% subplot(1,2,2); image_localColormap(toeplitz(1:4), summer(10));

props = {'CLim',        'auto',         'CHAR|DOUBLE[2]';
         'EdgeColor',   'none',         'CHAR';
         'Optimize',    'rows',         'CHAR'};

opt= opt_proplistToStruct(varargin{:});
[opt isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

[sy,sx]= size(C);
if isdefault.Optimize && sx==1,
  opt.Optimize= 'columns';
end

if isequal(opt.CLim, 'auto'),
  opt.CLim= [min(C(:)) max(C(:))];
end
nCols= size(cmap, 1);

hold_state= ishold;
Col= 1 + nCols*(C-opt.CLim(1))/diff(opt.CLim);
Col= min(nCols, floor(Col));
switch(lower(opt.Optimize(1:min(3,end)))),
 case 'row',
  for y= 1:sy,
    yy= y + [-0.5 0.5];
    inter= [1 1+find(diff(Col(y,:))) sx+1];
    for xi= 1:length(inter)-1,
      xx= inter([xi xi+1]) - 0.5;
      h= fill(xx([1 2 2 1]), yy([1 1 2 2]), cmap(Col(y,inter(xi)),:));
      set(h, 'EdgeColor',opt.EdgeColor);
      hold on;
    end
  end
 case 'col',
  for x= 1:sx,
    xx= x + [-0.5 0.5];
    inter= [1; 1+find(diff(Col(:,x))); sy+1];
    for yi= 1:length(inter)-1,
      yy= inter([yi yi+1]) - 0.5;
      h= fill(xx([1 2 2 1]), yy([1 1 2 2]), cmap(Col(inter(yi),x),:));
      set(h, 'EdgeColor',opt.EdgeColor);
      hold on;
    end
  end
 otherwise,
  error('Unknown policy for property <Optimize>.');
end
if ~hold_state,  %% restore original hold state
  hold off;
end
set(gca, 'xLim',[0.5 sx+0.5], 'yLim',[0.5 sy+0.5], 'box','on', ...
         'xTick',[], 'yTick',[]);
