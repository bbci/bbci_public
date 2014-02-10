C= 2;
T= 10000;
cnt= struct('fs', 100);
cnt.x= 50*randn(T, C);
cnt.clab= str_cprintf('Ch%d', 1:C);

M= 100;
mrk= struct; %('fs', cnt.fs);
mrk.time= round(linspace(0, T/cnt.fs*1000, M+2));
mrk.time([1 end])= [];
%mrk.desc= str_cprintf('S%3d', ceil(rand(1,M)*10))';
mrk.desc= ceil(rand(1,M)*10);


% --- Setup a very simple system for (simulated) online processing
bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk};
bbci.source.log.output= 'screen';
data= bbci_recordSignals(bbci, '/tmp/rec_test');

[cnt_re, mrk_re]= file_readBV(data.source.record.filename);

isequal(cnt.clab, cnt_re.clab)
max(abs(cnt.x(:)-cnt_re.x(:)))

isequal(mrk.pos, mrk_re.pos(2:end))
isequal(mrk.desc, mrk_re.desc(2:end))

