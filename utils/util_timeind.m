function idx= util_timeind(dat, ival)
%UTIL_TIMEIND - Get indices corresponding to samplds within a given interval

misc_checkType(dat, 'STRUCT(x fs)');
misc_checkType(ival, 'DOUBLE[2]');

if isfield(dat, 't'),
  % epoched data
  si= 1000/dat.fs;
  len_sa= round(diff(ival)/si);
  [~, pos_zero]= min(abs(dat.t));
  core_ival= [ceil(ival(1)/si) floor(ival(2)/si)];
  addone= diff(core_ival)+1 < len_sa;
  pos_end= pos_zero + floor(ival(2)/si) + addone;
  idx= [-len_sa:-1] + pos_end;
else
  % continuous data
  error('not implemented');
end
