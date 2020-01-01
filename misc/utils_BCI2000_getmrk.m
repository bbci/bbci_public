function [mrk] = utils_BCI2000_getmrk(parameters, states)
% UTILS_BCI2000_GETMRK - create a mrk conveient struct
%
%Synopsis:
% mrk = utils_BCI2000_getmrk(parameters, states)
% 
%
%Arguments:
% parameters - BCI2000 session parameters such as SamplingRate etc...
% states - BCI2000 session states such StimulusCode etc...
%Returns:
% creates folder and saves the converted 
% MRK - mrk struct
%  .time - defines the time points of events in msec (DOUBLE [1 #events])
%  .event - structure of further information; 
%          each field of mrk.event provides information that is specified 
%          for each event, given in arrays that index the events in their first 
%           dimension.
%  .y - class labels (DOUBLE [#classes #events])
%  .className - class names (CELL {1 #classes})
%  .desiredPhrase - text to spell
% Okba Bekhelifi, LARESI, USTO-MB <okba.bekhelifi@univ-usto.dz>
% 02-2017

% 
targetSamples = states.StimulusType==1;
target = states.StimulusCode(targetSamples);
target = unique(target);
% 
stimlutationDuration = (parameters.StimulusDuration.NumericValue / 10^3) * parameters.SamplingRate.NumericValue;
stimulationStart = find(states.StimulusCode ~=0);
stimulationStart = stimulationStart(1:stimlutationDuration:end);
% 
mrk.time = stimulationStart';
desc = states.StimulusCode(stimulationStart);
targetIndices = find(desc==target(1) | desc==target(2));
desc(targetIndices) = desc(targetIndices) + 10;
mrk.event.desc = desc;
% 
y = zeros(2,length(desc));
targetIndices = desc >10;
nontargetIndices = ~targetIndices;
y(1,targetIndices) = 1;
y(2,nontargetIndices) = 1;
mrk.y = y;
% 
mrk.className = {'target', 'nontarget'};
% 
mrk.desiredPhrase = parameters.TextToSpell.Value;
end

