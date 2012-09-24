function str= util_toString(var, varargin)
% UTIL_TOSTRING - Convert value of a variable into an (evaluatable) string
%
%Synopsis:
%  STR= util_toString(VAR, <OPT>
%
%Arguments:
%  VAR  -  Variable which is to be converted into a string
%  OPT  -  Struct or property/value list of optional properties:
%    'NumericFormat' [CHAR '%f']  Format string for printing numeric values
%    'MaxDim'        [INT  inf]  Print arrays up to this number of dimensions
%    'MAXNumel'      [INT  inf]  Print arrays up to this number of elements


props= {'NumericFormat'   '%f'    'CHAR'
        'MaxDim'          inf     'INT'
        'MaxNumel'        inf     'INT'
        'inrecursion'     0       'BOOL'
       };

if nargin==0,
  str= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
if ~opt.inrecursion,
  opt_checkProplist(opt, props);
  opt.inrecursion= 1;
end

if numel(var)>opt.MaxNumel,
  str= sprintf('[%s %s]', str_vec2str(size(var), '%d', 'x'), ...
               upper(class(var)));
  return;
end

str= [];
if islogical(var)
  if prod(size(var))==1
    if var==0, str = 'false'; else str = 'true';end
  elseif isempty(var)
    str = '[]';
  elseif ndims(var)<=2 && size(var,2)==1
    str = sprintf('%s''',util_toString(var', opt));
  elseif (ndims(var)<=2 && size(var,1)==1) || ...
        (ndims(var)<=2 && opt.MaxDim>=2),
    str = '[';
    for i = 1:size(var,1)
      for j = 1:size(var,2)
%        str = [str , util_toString(var(i,j), opt),','];
        str = [str , util_toString(var(i,j), opt),' '];
      end
      str = [str(1:end-1),';'];
    end
    str = [str(1:end-1),']'];
  elseif ndims(var)<=opt.MaxDim,
    str = '[';
    nd = ndims(var);
    sv = size(var); sv(end)=[];
    va = permute(var,[nd,1:nd-1]);
    for i = 1:size(var,nd)
      v = va(i,:)';
      v = reshape(v,sv);
      str = [str util_toString(v, opt) ';'];
    end
    str = [str(1:end-1),']'];
  end
elseif isnumeric(var)
  if prod(size(var))==1
    if var==round(var),
      str = sprintf('%d',var);
    else
      str = sprintf(opt.NumericFormat, var);
    end
  elseif isempty(var)
    str = '[]';
  elseif ndims(var)<=2 && size(var,2)==1
    str = sprintf('%s''',util_toString(var', opt));
  elseif (ndims(var)<=2 && size(var,1)==1) || ...
        (ndims(var)<=2 && opt.MaxDim>=2),
    str = '[';
    for i = 1:size(var,1)
      for j = 1:size(var,2)
%        str = [str , util_toString(var(i,j), opt),','];
        str = [str , util_toString(var(i,j), opt),' '];
      end
      str = [str(1:end-1),';'];
    end
    str = [str(1:end-1),']'];
  elseif ndims(var)<=opt.MaxDim,
    str = '[';
    nd = ndims(var);
    sv = size(var); sv(end)=[];
    va = permute(var,[nd,1:nd-1]);
    for i = 1:size(var,nd)
      v = va(i,:)';
      v = reshape(v,sv);
      str = [str util_toString(v, opt) ';'];
    end
    str = [str(1:end-1),']'];
  end
elseif ischar(var)
  if ndims(var)<=2 & size(var,1)==1
    str = ['''',var,''''];
  elseif isempty(var)
    str = '''''';
  elseif ndims(var)<=2
    str = '[';
    for i = 1:size(var,1)
      str = [str util_toString(var(i,:), opt), ';'];
    end
    str = [str(1:end-1),']'];
  else
    str = '[';
    nd = ndims(var);
    sv = size(var); sv(end)=[];
    va = permute(var,[nd,1:nd-1]);
    for i = 1:size(var,nd)
      v = va(i,:)';
      v = reshape(v,sv);
      str = [str util_toString(v, opt) ';'];
    end
    str = [str(1:end-1),']'];
  end
elseif iscell(var)
   if prod(size(var))==1
    str = ['{',util_toString(var{1}, opt),'}'];
  elseif isempty(var)
    str = '{}';
  elseif ndims(var)<=2 & size(var,2)==1
    str = sprintf('%s''',util_toString(var', opt));
  elseif (ndims(var)<=2 && size(var,1)==1) || ...
        (ndims(var)<=2 && opt.MaxDim>=2),
    str = '{';
    for i = 1:size(var,1)
      for j = 1:size(var,2)
        str = [str , util_toString(var{i,j}, opt),','];
      end
      str = [str(1:end-1),';'];
    end
    str = [str(1:end-1),'}'];
  elseif ndims(var)<=opt.MaxDim,
    str = '{';
    nd = ndims(var);
    sv = size(var); sv(end)=[];
    va = permute(var,[nd,1:nd-1]);
    for i = 1:size(var,nd)
      v = va(i,:)';
      v = reshape(v,sv);
      str = [str util_toString(v, opt) ';'];
    end
    str = [str(1:end-1),'}'];
  end
elseif isstruct(var)
  if prod(size(var)) == 1
    str = 'struct(';
    a = fieldnames(var);
    for i = 1:length(a)
      str = [str, '''', a{i}, ''',', util_toString(getfield(var,a{i}), opt), ...
	     ','];
    end
    str = [str(1:end-~isempty(a)),')'];
  elseif isempty(var)
    str = 'struct([])';
  elseif ndims(var)<=2 && size(var,2)==1
    str = sprintf('%s''',util_toString(var', opt));
  elseif (ndims(var)<=2 && size(var,1)==1) || ...
        (ndims(var)<=2 && opt.MaxDim>=2),
    str = '[';
    for i = 1:size(var,1)
      for j = 1:size(var,2)
        str = [str , util_toString(var(i,j), opt),','];
      end
      str = [str(1:end-1),';'];
    end
    str = [str(1:end-1),']'];
  elseif ndims(var)<=opt.MaxDim,
    str = '[';
    nd = ndims(var);
    sv = size(var); sv(end)=[];
    va = permute(var,[nd,1:nd-1]);
    for i = 1:size(var,nd)
      v = va(i,:)';
      v = reshape(v,sv);
      str = [str util_toString(v, opt) ';'];
    end
    str = [str(1:end-1),']'];
  end
elseif isa(var, 'function_handle'),
  str= ['@' func2str(var)];
end

if isempty(str),
  str= sprintf('[%s %s]', str_vec2str(size(var), '%d', 'x'), ...
               upper(class(var)));
end
