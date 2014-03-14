function mnt = mnt_restrictNIRSMontage(mnt,varargin)
%MNT_RESTRICTNIRSMONTAGE - restrict a NIRS montage to a subset of channels
%
%Descpription:
% Restricts the NIRS montage by selecting (a) specified NIRS channels
% and/or (b) sources or detectors and keeping only the corresponding NIRS
% channels and/or (c) keeping only informative NIRS channels (i.e. channels
% corresponding to a relatively small source-detector distance).
%
%Synopsis:
% MNT = mnt_restrictNIRSMontage(MNT, CHANS, <OPT>)
% MNT = mnt_restrictNIRSMontage(MNT, <OPT>)
%
%Input:
% MNT:   NIRS montage
% CHANS: restrict montage to these NIRS channels (can contain any
%        wildcards * and #; see chanind). Must be a cell array of strings.
% OPT:   struct or property/value list of optional properties:
% .Source    - a cell array containing the labels or physical numbers of
%              sources that are to be selected. All other sources and NIRS
%              channels containing these sources are removed. Default {}
%              (ie all sources are considered).
%              The cell array can also contain the keyword 'not' as first
%              element, in which the selection is inverted (ie {'not'
%              'Fz'} would remove Fz and preserve all *other* sources).
% .Detector  - The same as 'Source' for the detectors.
% .Dist      - gives the maximum distance [in cm] between source/detector pairs. 
%              If set, source/detector pairs with a larger distance are
%              removed.  Assuming a head radius of default 10 cm (set 'headRadius').
%              The default value of dist is 3.5 - if you do not want
%              channels to be reduced at all according to distance, set
%              dist to [].
% .RemoveOptodes - if 1, the non-selected optodes are not only removed
%              from the NIRS channels (mnt.clab field) but also from the
%              corresponding source and detector fields (mnt.source and
%              mnt.detector). (default 1)
%
%Output:
% MNT: updated montage
%
%Note: Use proc_selectChannels to reduce the NIRS data (cnt, dat, epo) 
%      according to the new montage.
%
%See also: mnt_restrictMontage

% matthias.treder@tu-berlin 2011
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert February 2014 (ready for public BBCI toolbox) (jan@mehnert.org)

props={ 'Chans'         {}      'CHAR|CELL{CHAR}'
        'Source'        {}      'CHAR|CELL{CHAR}'
        'Detector'      {}      'CHAR|CELL{CHAR}'
        'RemoveOptodes' 1       'BOOL'
        'HeadRadius'    10      'DOUBLE'
        'Dist'          3.5     'DOUBLE'
       };
                 
if nargin==0,
    mnt= props; return
end

if nargin>1 && mod(nargin,2)==0 %% first varargin is CHANS
  if numel(varargin)>1
    opt = opt_proplistToStruct(varargin{2:end});
    opt.Chans = varargin{1};
  elseif isstruct(varargin{1})
    opt = varargin{1};
  else
    opt = struct();
    opt.Chans = varargin{1};
  end
else
  opt = opt_proplistToStruct(varargin{:});
end

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(mnt, 'STRUCT');

if ischar(opt.Source)
  opt.Source = {opt.Source};
end
if ischar(opt.Detector)
  opt.Detector = {opt.Detector};
end
if ischar(opt.Chans)
  opt.Chans = {opt.Chans};
end
                
% Select sources and/or detectors
if ~isempty(opt.Source)
  selSou = mnt.source.clab(util_chanind(mnt.source,opt.Source));
  if opt.RemoveOptodes
    mnt.source = mnt_restrictMontage(mnt.source,selSou);
  end
end
if ~isempty(opt.Detector)
  selDet = mnt.detector.clab(util_chanind(mnt.detector,opt.Detector));
  if opt.RemoveOptodes
    mnt.detector = mnt_restrictMontage(mnt.detector,selDet);
  end
end

% Find connector for source-detector labels (non-alphanumeric character)
str = str_head(mnt.clab);
%[~,~,~,connector] = regexp(str,'[^\w]');
[dummy,dummy,dummy,connector] = regexp(str,'[-_\W]');
connector = cell2mat(unique(cell_flaten(connector)));
if isempty(connector)
  connector = '';
elseif numel(connector)>1
  error('Multiple connectors in NIRS clab: [%s]',[connector{:}])
end

% Select specified NIRS channels
if ~isempty(opt.Chans)
  mnt = mnt_restrictMontage(mnt,opt.Chans,{'ignore' connector}); 
end

% Restrict NIRS channels by removing the deleted sources/detectors
if ~isempty(opt.Source) || ~isempty(opt.Detector)
  if isempty(opt.Source), selSou = '*'; end
  if isempty(opt.Detector), selDet = '*'; end
  if ~iscell(selSou), selSou = {selSou}; end
  % Build selection string
  sel = strcat(selSou,connector);
  %sel = cell_flaten(cellfun('strcat',sel,selDet));
  sel=cell_flaten(strcat(sel,selDet));
  mnt = mnt_restrictMontage(mnt,sel);
end


% Reduce NIRS channels according to source-detector distance
if ~isempty(opt.Dist)
  dist = mnt.angulardist * opt.HeadRadius;   % distances in cm
  sel = find(dist<opt.Dist);  
  mnt = mnt_restrictMontage(mnt,sel);
end
