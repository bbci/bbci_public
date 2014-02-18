function grid= mntutil_getGrid(displayMontage)
%
%Synposis:
% GRID= mntutil_getGrid(DISPLAYMONTAGE)
%
%Input:
% DISPLAYMONTAGE: any *.mnt file in EEG_CFG_DIR, 
%                 e.g., 'small', 'medium', 'large',
%                 or a string defining the montage
%
%Output:
% GRID: 2-d cell array containing the channel labels

global EEG_CFG_DIR;

if ismember(',', displayMontage,'legacy') || ismember(sprintf('\n'), displayMontage,'legacy'),
  readFcn= 'strread';
  montage= displayMontage;
else
  readFcn= 'textread';
  montage= fullfile(EEG_CFG_DIR, [displayMontage '.mnt']);
  if ~exist(montage, 'file'),
    error(sprintf('unknown montage (checked %s)', ...
                  montage));
  end
end
grid= feval(readFcn, montage, '%s');
width= 1 + sum(grid{1}==',');
grid= cell(1, width);
[grid{:}]= feval(readFcn, montage, repmat('%s',1,width), 'delimiter',',');
grid= [grid{:}];
