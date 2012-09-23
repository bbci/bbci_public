function [cnt,mrk] = file_NIRSreadMatlab(filename)
filename
mnt=make_NIRSmnt;

load(filename)

cnt1.x=ni.dat;
cnt1.fs=ni.sf;
cnt1.clab=mnt.clab;
cnt1.title=filename;

% mrk1.pos=ni.mrk(:,1)';
% mrk1.toe=ni.mrk(:,2)';
% mrk1.fs=ni.sf;

mrk1.time=ni.mrk(:,1)'/cnt1.fs*1000;
mrk1.desc=ni.mrk(:,2)';
mrk1.className={'left','right'};
mrk1.y=zeros(2,size(mrk1.desc,2));
mrk1.y(1,:)=mrk1.desc==1;
mrk1.y(2,:)=mrk1.desc==2;

load([filename '02.mat'])
cnt2.x=ni.dat;
cnt2.fs=ni.sf;
cnt2.clab=mnt.clab;
cnt2.title=[filename '02.mat']

% mrk2.pos=ni.mrk(:,1)';
% mrk2.toe=ni.mrk(:,2)';
% mrk2.fs=ni.sf;

mrk2.time=ni.mrk(:,1)'/cnt2.fs*1000;
mrk2.desc=ni.mrk(:,2)';
mrk2.className={'left','right'};
mrk2.y=zeros(2,size(mrk2.desc,2));
mrk2.y(1,:)=mrk2.desc==1;
mrk2.y(2,:)=mrk2.desc==2;

[cnt,mrk] = proc_appendCnt(cnt1,cnt2,mrk1,mrk2);

cnt.x=cnt.x(:,25:end);