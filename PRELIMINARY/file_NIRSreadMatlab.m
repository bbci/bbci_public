function [cnt,mrk] = file_NIRSreadMatlab(filename)
% [cnt,mrk] = file_NIRSreadMatlab(filename)
% this is a temporary (and very rudimentary) function 
% to read pre-processed NIRS files

mnt=make_NIRSmnt;


if ~ismember('*', filename)
    
    load(filename)
    cnt.x=ni.dat;
    cnt.fs=ni.sf;
    cnt.clab=mnt.clab;
    cnt.title=filename;
    mrk.time=ni.mrk(:,1)'/cnt.fs*1000;
    mrk.desc=ni.mrk(:,2)';
    mrk.className={'left','right'};
    mrk.y=zeros(2,size(mrk.desc,2));
    mrk.y(1,:)=mrk.desc==1;
    mrk.y(2,:)=mrk.desc==2;
    disp(sprintf('%s loaded',filename))
else
    load(filename(1:end-1))
    cnt1.x=ni.dat;
    cnt1.fs=ni.sf;
    cnt1.clab=mnt.clab;
    cnt1.title=[filename(1:end-1) '02.mat']
    mrk1.time=ni.mrk(:,1)'/cnt1.fs*1000;
    mrk1.desc=ni.mrk(:,2)';
    mrk1.className={'left','right'};
    mrk1.y=zeros(2,size(mrk1.desc,2));
    mrk1.y(1,:)=mrk1.desc==1;
    mrk1.y(2,:)=mrk1.desc==2;
    
    load([filename(1:end-1) '02.mat'])
    cnt2.x=ni.dat;
    cnt2.fs=ni.sf;
    cnt2.clab=mnt.clab;
    cnt2.title=[filename(1:end-1) '02.mat']
    mrk2.time=ni.mrk(:,1)'/cnt2.fs*1000;
    mrk2.desc=ni.mrk(:,2)';
    mrk2.className={'left','right'};
    mrk2.y=zeros(2,size(mrk2.desc,2));
    mrk2.y(1,:)=mrk2.desc==1;
    mrk2.y(2,:)=mrk2.desc==2;
    
    [cnt,mrk] = proc_appendCnt(cnt1,cnt2,mrk1,mrk2);
    disp(sprintf('%s loaded',filename))

end
% select only oxy channels:
% TODO: output both oxy and deoxy timeseries
%cnt.x=cnt.x(:,25:end);