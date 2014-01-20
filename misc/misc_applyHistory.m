function obj = misc_applyHistory(obj,ht)
%MISC_APPLYHISTORY  - Applies function call(s) recorded in a history struct
%                     to an object.
%
%Synopsis:
%  MISC_APPLYHISTORY(OBJ,HT)
%
%Arguments:
%  OBJ:     struct with neuro data, or montage, or marker
%  HT:      history struct (or cell array of structs)
%
%Returns:
%  OBJ:     the modified object
%
%Examples:
% Apply the history saved in dat to a new dataset dat_new:
% misc_history_apply(dat_new,dat.history)
%
% See also: misc_history

% Matthias Treder 2012

misc_checkType(obj,  'STRUCT')
misc_checkType(ht,  'CELL|STRUCT')

if isstruct(ht), ht = {ht}; end;

for ii=1:numel(ht)
  call = ht{ii};
  % Find the parameter that corresponds to the object
  % the object is the only entry not listed as a separate field
  obj_idx = find(ismember(call.fcn_params,'obj','legacy')); 
  nnamed= numel(call.fcn_params);
  nvarargin = sum(cell2mat(regexp(fieldnames(call),'^varargin\d*$')));
  params = cell(nnamed+nvarargin,1);
  for jj=1:numel(params)
    if jj==obj_idx            % object
      params{jj} = obj;
    elseif jj<=nnamed         % named arguments
      params{jj} = call.(call.fcn_params{jj});
    else                      % varargins
      params{jj} = call.(sprintf('varargin%d',jj-nnamed));
    end
  end
  
  % Call function
  obj = feval(call.fcn,params{:});
   
end