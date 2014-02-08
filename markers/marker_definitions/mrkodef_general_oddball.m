function mrk= mrkodef_general_oddball(mrko, varargin)


%% Set default values
stimDef= {[21:39], [1:19];
          'target','non-target'};
respDef= {-16, -8, -24;
          'left', 'right', 'both'};
miscDef= {100, 252, 253;
          'cue off', 'start', 'end'};

%% Build opt struct from input argument and/or default values
props = {'StimDef', stimDef;
       'RespDef', respDef; ...
       'MiscDef', miscDef; ...
       'Matchstimwithresp', 1; ...
       'OptMatchResp', {}; ...
       'OffsetCountingResponse', []; ...
       'MaxCountingResponse', 199};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt,props);


%% Get markers according to the stimulus class definitions
mrk_stim= mrk_defineClasses(mrko, opt.StimDef);

if ~isempty(opt.OffsetCountingResponse),
  % TODO
  cmatch= str_cprintf('S%3d', opt.OffsetCountingResponse:opt.MaxCountingResponse);
  idx= strpatternmatch(cmatch, mrko.desc);
  mrk_stim.counting_response= apply_cellwise2(mrko.desc(idx), ...
          inline('str2num(x(2:end))','x')) - opt.OffsetCountingResponse;
end

if isempty(opt.RespDef),
  mrk= mrk_stim;
elseif opt.Matchstimwithresp,
  mrk_resp= mrk_defineClasses(mrko, opt.RespDef);
  [mrk, istim, iresp]= ...
      mrk_matchStimWithResp(mrk_stim, mrk_resp, ...
                            'missingresponse_policy', 'accept', ...
                            'multiresponse_policy', 'first', ...
                            'removevoidclasses', 0, ...
                            opt.OptMatchResp{:});
  ivalid= find(~mrk.missingresponse);
  if size(mrk_resp.y,1)>1,
    mrk.ishit= any(mrk.y(:,ivalid)==mrk_resp.y([1:size(mrk.y,1)],iresp));
    mrk= mrk_addIndexedField(mrk, 'ishit');
  end
else
  mrk= mrk_stim;
  mrk.resp= mrk_defineClasses(mrko, opt.RespDef);
end

if ~isempty(opt.MiscDef),
  mrk.misc= mrk_defineClasses(mrko, opt.MiscDef);
end
