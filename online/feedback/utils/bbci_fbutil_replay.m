function bbci_fbutil_replay(logfile, varargin)

opt= opt_proplistToStruct(varargin{:});
props= {'Realtime'   1       '!DOUBLE[1]'
        'FbOpt'      struct  'STRUCT'};
opt= opt_setDefaults(opt, props);

logline= textread(logfile, '%s', 'delimiter','');

ii= strmatch('#fcn = ', logline(1:min(10,length(logline))));
fcn= sscanf(logline{ii}, '#fcn = @%s');

idx= strmatch('#opt.', logline(1:min(1000,length(logline))));
fbopt= struct;
for ii= idx',
  eval(['fb' logline{ii}(2:end) ';']);
end
fbopt= struct_copyFields(fbopt, opt.FbOpt);

HH= feval([fcn '_init'], fbopt);
[handles, H]= bbciutil_handleStruct2Vector(HH);

k0= strmatch('# Starting', logline(1:min(1000,length(logline))));

starting_time= tic;
for k= k0+1:length(logline),
  if strncmp('# TICK', logline{k}, 6),
    ticktime= strread(logline{k}, '# TICK at %fs', 'delimiter','');
    wait_for_tick= 1;
    while wait_for_tick,
      wait_for_tick= toc(starting_time) < ticktime/opt.Realtime;
    end
    drawnow;
  elseif strncmp('# TRIGGER', logline{k}, 9),
  else
    n= min(find(logline{k}=='>'));
    handle_idx= str2double(logline{k}(1:n-1));
    prop= eval(logline{k}(n+1:end));
    set(handles(handle_idx), prop{:});
  end
end
