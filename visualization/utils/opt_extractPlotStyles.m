function [AxesStyle, LineStyle]= opt_extractPlotStyles(opt)
%OPT_EXTRACTPLOTSTYLES - Extract graphic object properties
%
%Synposis:
% [AXESSTYLE, LINESTYLE]= opt_extractPlotStyles(OPT)
%
%Input:
% OPT: Property names to be extracted
%
%Output:
% AXESSTYLE: Axes properties extracted
% LINESTYLE: Line properties extracted

StyleList= {'Box', 'Visible', ...
             'TickLength', 'TickDir', 'TickDirMode', ...
             'XGrid', 'XTick', 'XTickLabel', ...
             'XTickMode', 'XTickLabelMode', ...
             'XLim', 'XScale', 'XAxisLocation', 'XColor', ...
             'YGrid', 'YTick', 'YTickLabel', 'YDir', ...
             'YyTickMode', 'YTickLabelMode', ...
             'YLim', 'YScale', 'YAxisLocation', 'YColor', ...
             'ColorOrder', 'LineStyleOrder', 'GridLineStyle', ...
             'FontAngle', 'FontName', 'FontSize', 'FontUnits', 'FontWeight'};
ai= 0;
AxesStyle= {};
OptFields= fieldnames(opt);
for is= 1:length(StyleList),
  sm= strmatch(lower(StyleList{is}), lower(OptFields), 'exact');
  if length(sm)==1,
    ai= ai+2;
    AxesStyle(ai-1:ai)= {StyleList{is}, getfield(opt, OptFields{sm})};
  end
end

LineStyleList= {'LineWidth', 'LineStyle', ...
                'Marker', 'MarkerSize', 'MarkerEdgeColor', ...
                'MarkerFaceColor'};
ai= 0;
LineStyle= {};
for is= 1:length(LineStyleList),
  sm= strmatch(lower(LineStyleList{is}), lower(OptFields), 'exact');
  if length(sm)==1,
    ai= ai+2;
    LineStyle(ai-1:ai)= {LineStyleList{is}, getfield(opt, OptFields{sm})};
  end
end
