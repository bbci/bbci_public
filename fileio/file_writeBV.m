function props= file_writeBV(file, dat, mrk, varargin)
% FILE_WRITEBV - Write EEG file in BrainVision format
%
% Synopsis:
%   file_writeBV(FILE, DAT, MAK, <OPT>)
%
% Arguments:
%   FILE:  CHAR  name of the output file
%   DAT:   STRUCT of continuous or epoch signals
%   MRK:   STRUCT  for markers
%   OPT: PROPLIST - Structure or property/value list of optional properties:
%   'Scale': scaling factor used in the generic data format to bring
%          data from the int16 range (-32768 - 32767) to uV.
%          That means before saving signals are divided by
%          this factor.
%          Individual scaling factors may be specified for each
%          channel in a vector, or a global scaling as scalar;
%          default is 'auto'.
%   'WriteMrk': whether to write a marker file or not, default 1.
%   'WriteHdr': whether to write a header file or not, default 1.
%   'Folder': directory to which files are written


global BTB

opt= opt_proplistToStruct(varargin{:});
props= {'WriteMrk'      1            'BOOL'
        'WriteHdr'      1            'BOOL'
       };
props_writeBVheader= file_writeBVheader;
if nargin==0,
  props_writeBVmarkers= file_writeBVmarkers;
  props= opt_catProps(props, props_writeBVheader, props_writeBVmarkers);
  return;
end

props= opt_importProps(props, props_writeBVheader, ...
                       {'Scale','Folder','Precision','Unit'});
[opt, isdefault]= opt_setDefaults(opt, props, 1);
clear props

if isdefault.Unit,
  if isfield(dat, 'yUnit'),
    opt.Unit= dat.yUnit;
  elseif isfield(dat, 'cnt_info') && isfield(dat.cnt_info, 'yUnit'),
    opt.Unit= dat.cnt_info.yUnit;
  end
end

if fileutil_isAbsolutePath(file),
  fullName= file;
else
  fullName= fullfile(opt.Folder, file);
end

[T, nChans, nEpochs]= size(dat.x);
if nEpochs>1,
  cntX= permute(dat.x, [2 1 3]);
  cntX= reshape(cntX, [nChans T*nEpochs]);
  if ~exist('mrk','var'),
    nEpochs= floor(size(dat.x,1)/T);
    mrk= [];
    mrk.time= (1:nEpochs)*T/cnt.fs*1000;;
    mrk.y= ones(1,nEpochs);
    mrk.className= {'epoch'};
  end
else
  nEpochs= 0;
  cntX= dat.x';
end

if isequal(opt.Scale, 'auto'),
  if strcmpi(opt.Precision(1:3), 'int'),
    range= double([intmin(opt.Precision) intmax(opt.Precision)]);
  else
    range= [-1 1]*realmax(opt.Precision);
  end
  opt.Scale= (max(abs(cntX)+0.0001,[],2))/min(abs(range));
end

if length(opt.Scale)==1, 
  opt.Scale= opt.Scale*ones(nChans,1); 
end
cntX= diag(1./opt.Scale)*cntX;
if any(cntX(:)<range(1) | cntX(:)>range(2)),
  warning('data clipped: use other scaling');
end

subdir= fileparts(fullName);
if ~exist(subdir, 'dir'),
  parentdir= fileparts(subdir);
  if ~exist(parentdir, 'dir'),
    error('parent folder of %s not existing', subdir);
  end
  mkdir(subdir);
end
fid= fopen([fullName '.eeg'], 'wb');
if fid==-1, error(sprintf('cannot write to %s.eeg', fullName)); end
fwrite(fid, cntX, opt.Precision);
fclose(fid);

if opt.WriteHdr,
  opt_hdr= struct_copyFields(dat, {'fs','clab'});
  opt_hdr= struct_copyFields(opt_hdr, opt, {'Scale', 'Precision', 'Unit'});
  opt_hdr.DataPoints= size(cntX,2);
  file_writeBVheader(fullName, opt_hdr);
end

if opt.WriteMrk,
  file_writeBVmarkers(fullName, mrk, 'Fs',dat.fs);
end
