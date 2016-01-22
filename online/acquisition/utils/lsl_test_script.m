run = true;
last_mrk = '';

state_acquire= bbci_acquire_lsl('init');
cnt = zeros(64, 100);
mrk = zeros(1, 100);

step = 1;

while state_acquire.running
    [cnt_new, cntTime, mrkTime, mrkDesc, state_acquire]= bbci_acquire_lsl(state_acquire);
    
    if not(isempty(mrkDesc))
        fprintf('RECEIVED %s\n',  mrkDesc{1});
        fprintf('TIME %f \n',  mrkTime);
    end
    
    %   fprintf('Data %s at %f \n', cnt_new, cntTime);
%     fprintf('step %f \n', step)
%     last_mrk = mrkDesc;
%     last_mrkTime = mrkTime;
%     
%     cnt(:,step) = cnt_new;
    step = step + 1;
end
display('Streams broke off')