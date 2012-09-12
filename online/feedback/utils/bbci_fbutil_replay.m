function bbci_fbutil_replay(logfile, varargin)

opt= propertylist2struct(varargin{:});
opt= set_defaults(opt, ...
                  'realtime',1, ...
                  'fbopt', struct);

logline= textread(logfile, '%s', 'delimiter','');

ii= strmatch('#fcn = ', logline(1:min(10,length(logline))));
fcn= sscanf(logline{ii}, '#fcn = @%s');

idx= strmatch('#opt.', logline(1:min(1000,length(logline))));
fbopt= struct;
for ii= idx',
  eval(['fb' logline{ii}(2:end) ';']);
end
fbopt= copy_fields(fbopt, opt.fbopt);

HH= feval([fcn '_init'], fbopt);
[handles, H]= bbciutil_handleStruct2Vector(HH);

k0= strmatch('# Starting', logline(1:min(1000,length(logline))));

starting_time= tic;
for k= k0+1:length(logline),
  if strncmp('# TICK', logline{k}, 6),
    ticktime= strread(logline{k}, '# TICK at %fs', 'delimiter','');
    wait_for_tick= 1;
    while wait_for_tick,
      wait_for_tick= toc(starting_time) < ticktime*opt.realtime;
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
