function [mrk, istim, iresp, iresp2]= ...
    mrk_matchStimWithResp(mrk_stim, mrk_resp, varargin)
%MRK_MATCHSTIMWITHRESP - Match Stimulus with Response Markers
%
%Synopsis:
% [MRK, ISTIM, IRESP]= mrk_matchStimWithResp(MRK_STIM, MRK_RESP, <OPT>)
%
%Arguments:
% MRK_STIM: Marker structure of stimuli events as received by eegfile_loadBV
% MRK_RESP: Marker structure of response events as received by eegfile_loadBV
% OPT: struct or property/value list of optional properties:
%  'MinLatency': Only responses having at least this latency (in msec)
%     after stimulus are considered, default 0.
%  'MaxLatency': Only responses having at most this latency (in msec)
%     after stimulus are considered, default inf (but see next prop).
%  'AllowOvershoot': If false, only responses are considered, which are
%     received *before* the next stimulus, default false.
%  'Sort': Sort all events chronologically, default 1.
%  'RemoveVoidClasses': Void classes are removed from the list of classes.
%  'MissingresponsePolicy': Either 'reject' (default) or 'accept.
%  'MultiresponsePolicy': One of 'reject' (default), 'first', 'last'.
%
%Returns:
% MRK: Marker structure with those stimulus and response markers which
%    have been found as matching pairs
% ISTIM: Indices of stimulus events from MRK_STIM which were selected.
% IRESP: Indices of response events from MRK_RESP which were selected.

% blanker@cs.tu-berlin.de
props= {'MinLatency'        0           '!DOUBLE[1]';
        'MaxLatency'        inf         '!DOUBLE[1]';
        'AllowOvershoot'    0           '!DOUBLE[1]';
        'MissingresponsePolicy' 'reject'	'CHAR(reject accept)';
        'MultiresponsePolicy'   'reject'    'CHAR(reject first last)';
        'RemoveVoidClasses'	0           '!BOOL';
        'Sort'              1           '!BOOL'};
    

if nargin==0,
  mrk= props;
  return
end
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(mrk_stim, 'STRUCT(pos fs)');
misc_checkType(mrk_resp, 'STRUCT(pos fs)');

stim_msec= [mrk_stim.pos/mrk_stim.fs*1000 inf];
resp_msec= mrk_resp.pos/mrk_resp.fs*1000;

k= 0;
istim= [];
iresp= [];
multiple= [];
for ii= 1:length(mrk_stim.pos),
  valid_range(1)= stim_msec(ii) + opt.MinLatency;
  if opt.allow_overshoot,
    valid_range(2)= stim_msec(ii) + opt.MaxLatency;
  else
    valid_range(2)= min(stim_msec(ii+1), stim_msec(ii)+opt.MaxLatency);
  end
  ivalidresp= find(resp_msec>=valid_range(1) & ...
                   resp_msec<=valid_range(2));
  if length(ivalidresp)>1,
    hasmultiresp= 1;
    switch(lower(opt.MultiresponsePolicy)),
     case 'reject',
      ivalidresp= [];
     case 'first',
      ivalidresp= ivalidresp(1);
     case 'last',
      ivalidresp= ivalidresp(end);
     otherwise,
      error('unknown choice for multireponse_policy');
    end
  else 
    hasmultiresp= 0;
  end
  if ~isempty(ivalidresp) || ~strcmp(opt.MissingresponsePolicy,'reject'),
    k= k+1;
    istim(k)= ii;
    if isempty(ivalidresp),
      iresp(k)= NaN;
    else
      iresp(k)= ivalidresp;
    end
    multiple(k)= hasmultiresp;
  end
end

mrk= mrk_chooseEvents(mrk_stim, istim, opt);
if ~strcmp(opt.MissingresponsePolicy,'reject'),
  mrk.missingresponse= isnan(iresp);
  mrk= mrk_addIndexedField(mrk, 'missingresponse');
  iresp(mrk.missingresponse)= 1;
end
mrk.latency= mrk_resp.pos(iresp)*1000/mrk_resp.fs - mrk.pos*1000/mrk.fs;
mrk.resp_toe= mrk_resp.toe(iresp);
iresp2= iresp;
if isfield(mrk, 'missingresponse') && ~isempty(mrk.missingresponse),
  mrk.latency(mrk.missingresponse)= NaN;
  mrk.resp_toe(mrk.missingresponse)= NaN;
  iresp= iresp(~mrk.missingresponse);
  iresp2(mrk.missingresponse)= NaN;
end
mrk= mrk_addIndexedField(mrk, {'latency', 'resp_toe'});
if ~strcmpi(opt.MultiresponsePolicy, 'reject'),
  mrk.multiresponse= multiple;
  mrk= mrk_addIndexedField(mrk, 'multiresponse');
end

if opt.Sort,
  mrk= mrk_sortChronologically(mrk, opt);
end
