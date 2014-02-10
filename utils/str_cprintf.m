function C= cprintf(fmt, varargin)
%CPRINTF - Print array into cell array of string
%
%Synopsis:
%  cprintf(FORMAT, A, ...)
%
%Arguments
%  FORMAT - String that describes the format of the output as in sprintf
%
%Returns:
%  C - Cell array of strings
%
%Examples:
%  cprintf('chan #%d', 1:8)
%  cprintf('log(%d)= %f', 1:5, log(1:5))
%  cprintf('candidate #%d: %s', [1:3]', {'abraham','bebraham','zebraham'})


if isempty(varargin),
  C= {};
  return;
end

len= cellfun(@numel, varargin);
if any(diff(len)),
  error('all arguments must have the same number of elements');
end

N= len(1);
C= cell(N, 1);
Nv= length(varargin);
args= cell(1, Nv);
for n= 1:N,
  for m= 1:Nv,
    v= varargin{m};
    if iscell(v),
      args{m}= v{n};
    else
      args{m}= v(n);
    end
  end
  C{n}= sprintf(fmt, args{:});
end
C= reshape(C, size(varargin{1}));
