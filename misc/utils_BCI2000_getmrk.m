function [mrk] = utils_BCI2000_getmrk(parameters, states)
%UTILS_BCI2000_GET Summary of this function goes here
%   Detailed explanation goes here
% Okba BEKHELIFI - USTO-MB, <okba.bekhelifi@univ-usto.dz>
% Return markers in a BBCI format
% Input : parameters, states : BCI2000 data
% Output mrk
% created : 31/01/2017
% last modified : -- -- --

targetSamples = states.StimulusType==1;
target = states.StimulusCode(targetSamples);
target = unique(target);

stimlutationDuration = (parameters.StimulusDuration.NumericValue / 10^3) * parameters.SamplingRate.NumericValue;
stimulationStart = find(states.StimulusCode ~=0);
stimulationStart = stimulationStart(1:stimlutationDuration:end);

mrk.time = stimulationStart';
desc = states.StimulusCode(stimulationStart);
targetIndices = find(desc==target(1) | desc==target(2));
desc(targetIndices) = desc(targetIndices) + 10;
mrk.event.desc = desc;

y = zeros(2,length(desc));
targetIndices = desc >10;
nontargetIndices = ~targetIndices;
y(1,targetIndices) = 1;
y(2,nontargetIndices) = 1;
mrk.y = y;

mrk.className = {'target', 'nontarget'};

mrk.desiredPhrase = parameters.TextToSpell.Value;
end

