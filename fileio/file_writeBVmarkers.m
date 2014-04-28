function props= file_writeBVmarkers(file, mrk, varargin)
% FILE_WRITEBVMARKERS - Write Markers in BrainVision Format
%
% Synopsis:
%   file_writeBVmarkers(FILENAME, MRK, 'Property1',Value1, ...)
%
% Arguments:
%   FILE: string containing filename to save in.
%   MRK: marker structure.
%  
% Properties:
%     'Folder':   in which files are saved, if FILE is not an absolute path
%     'UseClassLabels': the class labels (given in mrk.y) are taken as markers
%                 this is default, only if there is no field mrk.event.desc
%     'DataFile': name of the corresponding .eeg file (default FILE)
%
% See also: eegfile_*
%

global BTB

if nargin<2,
  mrk= struct('time',[], 'y',[], 'event',struct);
end

default_UseClassLabels= 1;
if isfield(mrk,'event') && isfield(mrk.event,'desc'),
  default_UseClassLabels= 0;
end

props= {'Fs'               []                       '!DOUBLE'
        'Folder'           BTB.TmpDir               'CHAR'
        'UseClassLabels'   default_UseClassLabels   '!BOOL'
        'DataFile'         ''                       'CHAR'
       };
if nargin==0,
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props, 0);

if fileutil_isAbsolutePath(file),
  fullName= file;
else
  fullName= fullfile(opt.Folder, file);
end

[pathstr, fileName]= fileparts(fullName);
opt= opt_overrideIfDefault(opt, isdefault, 'DataFile', fileName);
% avoid output argument in this case
clear props

fid= fopen([fullName '.vmrk'], 'w');
if fid==-1, error(sprintf('cannot write to %s.vmrk', fullName)); end

fprintf(fid, ['Brain Vision Data Exchange Marker File, Version 1.0' 13 10]);
fprintf(fid, [13 10 '[Common Infos]' 13 10]);
fprintf(fid, ['DataFile=%s.eeg' 13 10], opt.DataFile);
fprintf(fid, [13 10 '[Marker Infos]' 13 10]);
pos= round(mrk.time/1000*opt.Fs);
if opt.UseClassLabels,
  [dmy, toe]= max(mrk.y);
  desc= str_cprintf('S%3d', toe);
else
  if iscell(mrk.event.desc),
    desc= mrk.event.desc;
  else
    toe= mrk.event.desc;
    desc= cell(length(toe), 1);
    for k= 1:numel(desc),
      if toe(k)>=0,
        desc{k}= sprintf('S%3d', toe(k));
      else
        desc{k}= sprintf('R%3d', toe(k));
      end
    end
  end
end
if ~(isfield(mrk.event,'type') && isfield(mrk.event,'clock')),
  % simple case, mrk is a usual (bbci) marker struct
  fprintf(fid, ['Mk1=New Segment,,1,1,0,00000000000000000000' 13 10]);
  for ie= 1:length(pos),
    fprintf(fid, ['Mk%d=Stimulus,%s,%d,1,0' 13 10], ie+1, desc(ie), ...
              pos(ie));
  end
else
  for im= 1:length(mrk.event.type)
    fprintf(fid, ['Mk%d=%s,%s,%u,%u,%u,%s' 13 10], im, ...
            mrk.event.type{im}, desc{im}, pos(im), ...
            mrk.event.length(im), mrk.event.chan(im), mrk.event.clock{im});
  end
end
fclose(fid);
