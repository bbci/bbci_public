function [mrk, istim, iresp, iresp2]= ...
    mrk_matchStimWithResp(mrk_stim, mrk_resp, varargin)
%MRK_MATCHSTIMWITHRESP - Match Stimulus with Response Markers
%
%Synopsis:
% [MRK, ISTIM, IRESP]= mrk_matchStimWithResp(MRK_STIM, MRK_RESP, <OPT>)
%
%Arguments:
% MRK_STIM: Marker structure of stimuli events as received by file_loadBV
% MRK_RESP: Marker structure of response events as received by file_loadBV
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


props= {'MinLatency'            0           '!DOUBLE[1]';
        'MaxLatency'            inf         '!DOUBLE[1]';
        'AllowOvershoot'        0           '!DOUBLE[1]';
        'MissingresponsePolicy' 'reject'    '!CHAR(reject accept)';
        'MultiresponsePolicy'   'reject'    '!CHAR(reject first last)';
        'RemoveVoidClasses'	0           '!BOOL';
        'Sort'                  1           '!BOOL'};
props_selectEvents = mrk_selectEvents;
props_sortChron= mrk_sortChronologically;

if nargin==0,
  mrk= props;
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
opt_selectEvents = opt_substruct(opt, props_selectEvents(:,1));
opt_sortChron = opt_substruct(opt, props_sortChron(:,1));

misc_checkType(mrk_stim, 'STRUCT(time)');
misc_checkType(mrk_resp, 'STRUCT(time)');

stim_msec= [mrk_stim.time inf];
resp_msec= mrk_resp.time;

k= 0;
istim= [];
iresp= [];
multiple= [];
for ii= 1:length(mrk_stim.time),
  valid_range(1)= stim_msec(ii) + opt.MinLatency;
  if opt.AllowOvershoot,
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

mrk= mrk_selectEvents(mrk_stim, istim, opt_selectEvents);
if ~strcmp(opt.MissingresponsePolicy,'reject'),
  mrk.event.missingresponse= isnan(iresp(:));
  iresp(mrk.event.missingresponse)= 1;
end
mrk.event.latency= mrk_resp.time(iresp)' - mrk.time';
iresp2= iresp;
if isfield(mrk.event, 'missingresponse') && ~isempty(mrk.event.missingresponse),
  mrk.event.latency(mrk.event.missingresponse)= NaN;
  iresp= iresp(~mrk.event.missingresponse);
  iresp2(mrk.event.missingresponse)= NaN;
end

if ~strcmpi(opt.MultiresponsePolicy, 'reject'),
  mrk.event.multiresponse= multiple(:);
end

if opt.Sort,
  mrk= mrk_sortChronologically(mrk, opt_sortChron);
end
