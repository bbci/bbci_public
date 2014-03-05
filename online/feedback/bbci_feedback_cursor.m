function data_feedback= bbci_feedback_cursor(ctrl, data_feedback)
%BBCI_FEEDBACK_CURSOR - BBCI Feedback: 1D Cursor Movement with Arrow Cues
%
%Synopsis:
% DATA_FEEDBACK= bbci_feedback_cursor(CTRL, DATA_FEEDBACK)
%
%Arguments:
% CTRL [DOUBLE] - Control signal to be received from the BBCI classifier
% DATA_FEEDBACK - STRUCT as used in bbci_apply. It contains the fields
%   'opt': Struct of optional properties of the feedback, see below
%   'state': Internally used by this function to store state information
%
%Output:
% DATA_FEEDBACK.opt - updated structure of properties
%
%Optional Properties:
%  duration_show_selected: time to show selection 
%  duration_before_free: time after target presentation, before cursor
%    starts moving
%  time_per_trial: maximum duration of a trial
%  timeout_policy: 'miss', 'reject', 'lastposition', 'hitiflateral'
%  rate_control: switch for rate control (opposed to position control) 
%  cursor_on: switch to show (or hide) cursor
%  response_at: switch to show response (hit vs miss) (1) at 'center' area,
%     or (2) at 'target' position, or (3) in the 'cursor' (cross), or
%     (4) 'none' not at all.
%  trials_per_run: number of trials in one run 
%  break_every: number of trial after which a break is inserted, 0 means no
%     breaks. Default: 0.
%  break_show_score: 1 means during breaks the score is shown, 0 means not.
%     Default: 1.
%  marker_active_spec: marker specification (cell array) of active cursor
%  marker_inactive_spec: marker specification (cell array) of inactive cursor
%  fixation_spec: marker specification (cell array) of fixation cross
%  background: color of figure background
%  color_hit: color for hit
%  color_miss: color for miss
%  color_reject: color for reject
%  color_target: color to indicate targets
%  color_nontarget: color of non-target
%  center_size: size of center area (for response in center)
%  target_width: width of target areas (normalized)
%  target_dist: distance of targets vertically from top and bottom
%  next_target: switch to show next target
%  next_target_width: width of next target indicator (normalized
%     within target width)
%  msg_spec: text specification (cell array) of messages 
%  points_spec: text specification (cell array) of points 
%  countdown: length of countdown before application starts [ms]
%  position: position of the figure (pixel)
%
%Markers written to parallel port
%    1: target in direction #1
%    2: target in direction #2
%   11: trial ended with cursor correctly on the left side
%   12: trial ended with cursor correctly on the right side
%   21: trial ended with cursor erroneously on the left side
%   22: trial ended with cursor erroneously on the right side
%   23: trial ended by time-out and opt.timeout_policy='miss'
%   24: trial ended by time-out and opt.timeout_policy='reject'
%   25: trial ended by time-out and opt.timeout_policy='hitiflateral'
%          and cursor was not lateral enough: reject
%   30: countdown starts
%   31: select goal side and indicate it
%   32: wait before cursor movement starts
%   33: in position control, cursor becomes active in center area
%   34: move cursor until target was hit or time-out
%   35: wait before next trial starts (or game is over)
%   41: first touch with cursor correctly in direction #1
%   42: first touch with cursor correctly in direction #2
%   51: first touch with cursor erroneously in direction #1
%   52: first touch with cursor erroneously in direction #2
%  200: init of the feedback
%  255: game ends

% Author(s): Benjamin Blankertz, Nov-2006


opt= data_feedback.opt;
DFS= data_feedback.state;
DFE= data_feedback.event;
if ~isfield(DFS,'starting'),
  DFS.starting= 1;
end
fbset= @bbci_fbutil_set;

if DFS.starting,
  DFS.starting= 0;
  props= {'countdown'   3000   'INT'
          'classes'   {'left','right'}  'CELL'
          'trigger_classes_list'   {}   'CELL'
          'duration'   3000   'INT'
          'duration_jitter'   0  'INT'
          'duration_before_free'   1000  'INT'
          'duration_show_selected'   1000   'INT'
          'duration_blank'   2000   'INT'
          'duration_until_hit'   1500   'INT'
          'duration_break'   15000   'INT'
          'duration_break_fadeout'   1000   'INT'
          'duration_break_post_fadeout'   1000   'INT'
          'touch_terminates_trial'   0   'INT'
          'remove_cue_at_end_of_trial'   0   'INT'
          'break_every'   20   'INT'
          'break_show_score'   1   'BOOL'
          'break_endswith_countdown'   1   'BOOL'
          'timeout_policy'  'lastposition'   'CHAR'
          'rate_control'    1   'BOOL'
          'input_range'   [-1 1]   'DOUBLE[2]'
          'cursor_on'   1   'BOOL'
          'response_at'   'none'   'CHAR'
          'trials_per_run'   100   'INT'
          'sequence'   []   'INT'
          'cursor_active_spec'    {'FaceColor',[0.6 0 0.5]}   'PROPLIST'
          'cursor_inactive_spec'   {'FaceColor',[0 0 0]}       'PROPLIST'
          'background'     0.5*[1 1 1]   'DOUBLE[1 3]'
          'color_hit'        [0 0.8 0]   'DOUBLE[1 3]'
          'color_miss'         [1 0 0]   'DOUBLE[1 3]'
          'color_reject'   [0.8 0 0.8]   'DOUBLE[1 3]'
          'color_center'   0.5*[1 1 1]   'DOUBLE[1 3]'
          'center_size'    0.15   'DOUBLE'
          'damping_in_target'   'quadratic'   'CHAR'
          'target_width'   0.075   'DOUBLE'
          'frame_color'  0.8*[1 1 1]   'DOUBLE[1 3]'
          'punchline'    0   'BOOL'
          'punchline_spec'         {'Color',[0 0 0], 'LineWidth',3}  'PROPLIST'
          'punchline_beaten_spec'  {'Color',[1 1 0], 'LineWidth',5}  'PROPLIST'
          'gap_to_border'   0.02   'DOUBLE'
          'msg_spec'      {'FontSize',0.15}    'PROPLIST'
          'points_spec'   {'FontSize',0.065}   'PROPLIST'
          'show_score'   0   'BOOL'
          'show_rejected'   0   'BOOL'
          'show_bit'   0   'BOOL'
          'log_state_changes',0   'BOOL'
          'verbose'   1   'BOOL'
          'fig'   1   'INT'
          'fs'   25   'DOUBLE'
          'pause_msg'   'pause'   'CHAR'
          'geometry'    [0 0 800 600]   '!DOUBLE[4]'
         };
  props_fbset= {'trigger_fcn'     []   'FUNC'
                'trigger_param'   {}   'CELL'};
  props_all= opt_catProps(props, props_fbset);
  [opt, isdefault]= opt_setDefaults(opt, props_all, 2);
  
  if ~ismember(opt.timeout_policy,{'hitiflateral','reject'}) ...
        && isdefault.show_rejected,
    [opt, isdefault]= opt_overrideIfDefault(opt, isdefault, ...
                                               'show_rejected', 0);
  end
  if opt.rate_control && ~strcmpi(opt.timeout_policy,'hitiflateral'),
    DFS.center_visible= 0;
  else
    DFS.center_visible= 1;
  end
  if ~opt.cursor_on && strcmp(opt.response_at, 'cursor'),
    opt.response_at= 'center';
  end
  data_feedback.opt= opt;
  
  [DFS.HH, DFS.cfd]= bbci_feedback_cursor_init(opt);
  [handles, DFS.H]= bbciutil_handleStruct2Vector(DFS.HH);
  DFE= fbset(data_feedback, 'init', handles);
  DFE= fbset(DFE, 200);

  DFS.stopwatch= 0;
  DFS.x= 0;
  DFS.degree= 0;
  DFS.lastdigit= NaN;
  DFS.lastno= NaN;
  DFS.timer= 0;
  DFS.lasttick= clock;
  DFS.timeeps= 0.25*1000/opt.fs;
  DFS.trial= 0;
  DFS.no= 0;
end

if DFS.no~=DFS.lastno,
  DFS.lastno= DFS.no;
  if DFS.no>=0 && opt.log_state_changes,
    DFE= fbset(DFE, 30+DFS.no);
  end
  if opt.verbose>1,
    fprintf('state: %d\n', DFS.no);
  end
end

if ~opt.rate_control && DFS.no>-2,
  DFS.x= ctrl;
  DFS.x= max(-1, min(1, DFS.x));
end

thisisnow= clock;
time_since_lasttick= 1000*etime(thisisnow, DFS.lasttick);
DFS.lasttick= thisisnow;

if DFS.no==0,
  if DFS.timer == 0,
    DFE= fbset(DFE, DFS.H.fixation, 'Visible','off');
  end
  digit= ceil((opt.countdown-DFS.timer)/1000);
  if digit~=DFS.lastdigit,
    DFE= fbset(DFE, DFS.H.msg, 'String',int2str(digit), 'Visible','on');
    DFS.lastdigit= digit;
  end
  if DFS.timer+DFS.timeeps >= opt.countdown,
    %% countdown terminates: prepare run
    DFE= fbset(DFE, DFS.H.msg, 'Visible','off');
    DFS.timer= 0;
    if DFS.trial==0,      %% otherwise we come from break inbetween runs
      DFS.punch= [-1 1];
      DFS.ishit= [];
      DFS.rejected= 0;
      if ~isempty(opt.sequence),
        seq= opt.sequence;
      else
        nTrials= opt.trials_per_run;
        nBlocks= floor(nTrials/opt.break_every);
        seq= [];
        for bb= 1:nBlocks,
          bseq= round(linspace(1, 2, opt.break_every));
          if mod(opt.break_every,2) && mod(bb,2),
            bseq(end)= 1;
          end
          pp= randperm(opt.break_every);
          seq= cat(2, seq, bseq(pp));
        end
        nLeftOvers= nTrials - length(seq);
        bseq= round(linspace(1, 2, nLeftOvers));
        pp= randperm(nLeftOvers);
        seq= cat(2, seq, bseq(pp));
      end
      DFS.sequence= [seq, 0];
      DFS.touched_once= 0;
    end
    DFS.no= 1;
  else
    DFS.timer= DFS.timer + time_since_lasttick;
  end
end

if DFS.no==1,   %% show a blank screen with fixation cross
  if DFS.timer == 0,
    DFE= fbset(DFE, DFS.H.cue, 'Visible','off');
    DFE= fbset(DFE, DFS.H.cursor, 'Visible','off');
    DFE= fbset(DFE, DFS.H.fixation, 'Visible','on');
  end
  if DFS.timer+DFS.timeeps >= opt.duration_blank,
    DFS.timer= 0;
    DFS.no= 2;
  end
  DFS.timer= DFS.timer + time_since_lasttick;
end

if DFS.no==2,  %% select goal side and indicate it
  DFS.trial_duration= opt.duration + opt.duration_jitter*rand;
  DFS.trial= DFS.trial + 1;
  if DFS.trial==1,
    DFS.stopwatch= 0;
  end    
  if DFS.trial<1,
    DFS.goal= ceil(2*rand);
  else
    DFS.goal= DFS.sequence(DFS.trial);
  end
  DFE= fbset(DFE, DFS.H.cue(DFS.goal), 'Visible','on');
  DFS.x= 0;
  DFS.timer= 0;
  DFS.no= 3;
  if isempty(opt.trigger_classes_list),
    triggi= DFS.goal;
  else
    cued_class= opt.classes{DFS.goal};
    triggi= strmatch(cued_class, opt.trigger_classes_list);
    if isempty(triggi),
      warning('cued class not found in trigger_classes_list');
      triggi= 10+DFS.goal;
    end
  end
  DFE= fbset(DFE, triggi);
end

if DFS.no==3,  %% wait before cursor movement starts
  if DFS.timer+DFS.timeeps >= opt.duration_before_free,
    DFS.no= 4;
  else
    DFS.timer= DFS.timer + time_since_lasttick;
  end
end

if DFS.no==4,  %% in position control, cursor becomes active in center area
  if opt.rate_control || abs(DFS.x)<opt.center_size,
    DFE= fbset(DFE, 60);
    if opt.cursor_on,
      DFE= fbset(DFE, DFS.H.fixation, 'Visible','off');
      ud= get(DFS.HH.cursor, 'UserData');
      DFE= fbset(DFE, DFS.H.cursor, 'Visible','on', ...
             opt.cursor_active_spec{:}, ...
             'XData',ud.xData, 'YData',ud.yData);
    end
    DFS.trialwatch= 0;
    DFS.no= 5;
  end
end

if DFS.no==5,  %% move cursor until target was hit or time-out
  if opt.rate_control,
    % clip input control signal, if range is specified
    if ~isempty(opt.input_range),
      ctrl= max(opt.input_range(1), min(opt.input_range(2), ctrl));
    end
    if abs(DFS.x)<1,
      DFS.x= DFS.x + ctrl/opt.fs/opt.duration_until_hit*1000;
    else
      switch(opt.damping_in_target),
       case 'linear',
        sec= (DFS.trial_duration-opt.duration_until_hit)/1000;
        frames= 1 + ceil( opt.fs * sec );
        DFS.x= DFS.x + ctrl * DFS.cfd.target_width / frames;
       case 'quadratic',
        slope= 1000/opt.duration_until_hit;
        yy= 1 - (abs(DFS.x)-1)/DFS.cfd.target_width;
        fac= yy*slope;
        DFS.x= DFS.x + ctrl*fac/opt.fs;
       otherwise
        error('option for damping_in_target unknown');
      end
    end
    DFS.x= max(-1-DFS.cfd.target_width, min(1+DFS.cfd.target_width, DFS.x));
  end
  
  trial_terminates= 0;
  
  %% cursor touches target
  if abs(DFS.x) >= 1,
    if opt.touch_terminates_trial,
      trial_terminates= 1;
      DFS.selected= sign(DFS.x)/2 + 1.5;
      ishit= (DFS.selected==DFS.goal);
      DFE= fbset(DFE, 10*(2-ishit)+DFS.selected);
    elseif ~DFS.touched_once,
      DFS.touched_once= 1;
      DFS.preselected= sign(DFS.x)/2 + 1.5;
      ishit= (DFS.preselected==DFS.goal);
      DFE= fbset(DFE, 30+10*(2-ishit)+DFS.preselected);
    end
  end
  
  %% timeout
  if DFS.trialwatch+DFS.timeeps >= DFS.trial_duration,
    trial_terminates= 1;
    switch(lower(opt.timeout_policy)),
     case 'miss',
      DFS.selected= [];
      ishit= 0;
      DFE= fbset(DFE, 23);  %% reject by timeout
     case 'reject',
      DFS.selected= [];
      ishit= -1;
      DFE= fbset(DFE, 24);  %% reject by timeout
     case 'lastposition',
      DFS.selected= sign(DFS.x)/2 + 1.5;
      ishit= (DFS.selected==DFS.goal);
      DFE= fbset(DFE, 10*(2-ishit)+DFS.selected);
     case 'hitiflateral',
      if abs(DFS.x)>opt.center_size,
        %% cursor is lateral enough (outside center): count as hit
        DFS.selected= sign(DFS.x)/2 + 1.5;
        ishit= (DFS.selected==DFS.goal);
        DFE= fbset(DFE, 10*(2-ishit)+DFS.selected);
      else
        %% cursor is within center area: count as reject
        DFS.selected= [];
        ishit= -1;
        DFE= fbset(DFE, 25);  %% reject by timeout and position
      end
     otherwise
      error('unknown value for OPT.timeout_policy');
    end
  end
  
  %% trial terminates: show response and update score
  if trial_terminates,
    DFE= fbset(DFE, DFS.H.cursor, opt.cursor_inactive_spec{:});
    if DFS.trial>0,
      if ishit==-1,
        DFS.rejected= DFS.rejected + 1;
      end      
      DFS.ishit(DFS.trial)= (ishit==1);
      nHits= sum(DFS.ishit(1:DFS.trial));
      nMisses= DFS.trial - DFS.rejected - nHits;
      if opt.verbose,
        fprintf('points: %03d - %03d  (%d rejected)\n', nHits, nMisses, ...
          DFS.rejected);
      end
      DFE= fbset(DFE, DFS.H.points(1), 'String',['hit: ' int2str(nHits)]);
      DFE= fbset(DFE, DFS.H.points(2), 'String',['miss: ' int2str(nMisses)]);
      DFE= fbset(DFE, DFS.H.rejected_counter, 'String',['rej: ' int2str(DFS.rejected)]);
      if ishit==1 && ~opt.touch_terminates_trial,
        ii= DFS.selected;
        if abs(DFS.x) > abs(DFS.punch(ii)),  %% beaten the punchline?
          DFS.punch(ii)= DFS.x;
          DFE= fbset(DFE, DFS.H.punchline(ii), 'XData',[1 1]*DFS.x, ...
                 opt.punchline_beaten_spec{:});
        end
      end
    end
    switch(lower(opt.response_at)),
     case 'center',
      DFS.H_indicator= DFS.H.center;
      ind_prop= 'FaceColor';
      DFE= fbset(DFE, DFS.H.center, 'Visible','on');
     case 'target',
      DFS.H_indicator= DFS.H.cue(DFS.goal);
      ind_prop= 'FaceColor';
     case 'cursor',
      DFS.H_indicator= DFS.H.cursor;
      ind_prop= 'Color';
     case 'none',
      DFS.H_indicator= [];
     otherwise,
      warning('value for property ''response at'' unrecognized.');
      DFS.H_indicator= DFS.H.target(DFS.selected);
    end
    if ~isempty(DFS.H_indicator),
      switch(ishit),
       case 1,
        DFE= fbset(DFE, DFS.H_indicator, ind_prop,opt.color_hit);
       case 0,
        DFE= fbset(DFE, DFS.H_indicator, ind_prop,opt.color_miss);
       case -1,
        DFE= fbset(DFE, DFS.H_indicator, ind_prop,opt.color_reject);
      end
    end
    DFS.timer= 0;
    if opt.remove_cue_at_end_of_trial,
      DFE= fbset(DFE, DFS.H.cue, 'Visible','off');
    end
    DFS.no= 6;
  end
  DFS.trialwatch= DFS.trialwatch + time_since_lasttick;
end

if DFS.no==6,  %% wait before next trial starts (or game is over)
  if DFS.timer+DFS.timeeps >= opt.duration_show_selected,
    switch(lower(opt.response_at)),
     case 'center',
      if DFS.center_visible,
        DFE= fbset(DFE, DFS.H.center, 'FaceColor',opt.color_center);
      else
        DFE= fbset(DFE, DFS.H.center, 'Visible','off');
      end
     case 'target',
     case 'cursor',
     case 'none',
    end
    DFE= fbset(DFE, DFS.H.punchline, opt.punchline_spec{:});
    if DFS.trial==length(DFS.sequence)-1,
        %% game over
        if ~opt.show_score,  %% show score at least at the end
          DFE= fbset(DFE, DFS.H.points, 'Visible','on');
        end
        if opt.show_bit,
          minutes= DFS.stopwatch/1000/60;
          acc= sum(DFS.ishit)/(DFS.trial-DFS.rejected);
          bpm= bitrate(acc) * opt.trials_per_run / minutes;
          msg= sprintf('%.1f bits/min', bpm);
          DFE= fbset(DFE, DFS.H.msg, 'String',msg, 'Visible','on');
        else
          msg= sprintf('thank you');
          DFE= fbset(DFE, DFS.H.msg, 'String',msg, 'Visible','on');
        end
        if opt.punchline,
          msg= sprintf('punch at  [%d %d]', ...
                       round(100*(DFS.punch-sign(DFS.punch))/DFS.cfd.target_width));
          DFE= fbset(DFE, DFS.H.msg_punch, 'String',msg, 'Visible','on');
        end
        if opt.rate_control,
          DFE= fbset(DFE, DFS.H.cursor, 'Visible','off');
        else
          DFE= fbset(DFE, DFS.H.cursor, opt.cursor_inactive_spec{:});
        end
        DFE= fbset(DFE, DFS.H.fixation, 'Visible','off');
        DFE= fbset(DFE, DFS.H.cue, 'Visible','off');
        DFE= fbset(DFE, 255);
        DFS.no= -1;
    elseif opt.break_every>0 && DFS.trial>0 && mod(DFS.trial,opt.break_every)==0,
      DFS.timer= 0;
      DFS.no= 7;
    else
      DFS.timer= 0;
      DFS.no= 1;
      data_feedback.state= DFS;
      data_feedback.event= DFE;
      data_feedback= bbci_feedback_cursor(ctrl, data_feedback);
      data_feedback.state.timer= ...
          data_feedback.state.timer + time_since_lasttick;
      return;
    end
  else
    DFS.timer= DFS.timer + time_since_lasttick;
  end
end

if DFS.no==7,   %% give a break where the score is (optionally) shown
  if DFS.timer == 0,
    if opt.break_show_score,
      nHits= sum(DFS.ishit(1:DFS.trial));
      msg= sprintf('%d : %d', nHits, DFS.trial - nHits - DFS.rejected);
    else
      msg= 'short break';    
    end
    DFE= fbset(DFE, DFS.H.msg, 'String',msg, 'Visible','on');
    DFE= fbset(DFE, DFS.H.center, 'Visible','off');
    DFE= fbset(DFE, DFS.H.cursor, 'Visible','off');
    DFE= fbset(DFE, DFS.H.fixation, 'Visible','off');
    DFE= fbset(DFE, DFS.H.cue, 'Visible','off');
  end
  if DFS.timer+DFS.timeeps >= opt.duration_break,
    DFS.timer= 0;
    DFS.no= 8;
  end
  DFS.timer= DFS.timer + time_since_lasttick;
end

if DFS.no==8,   %% score fade-out at the end of the break
  if DFS.timer+DFS.timeeps > opt.duration_break_fadeout+opt.duration_break_post_fadeout,
    DFS.timer= 0;
    if opt.break_endswith_countdown,
      DFS.no= 0;
    else
      DFS.no= 1;
    end
  elseif DFS.timer+DFS.timeeps <= opt.duration_break_fadeout,
    fade= (opt.duration_break_fadeout-DFS.timer)/opt.duration_break_fadeout;
    DFE= fbset(DFE, DFS.H.msg, 'Color',[0 0 0]*fade + opt.background*(1-fade));
    DFS.fadeout_finished= 0;
  else
    if ~DFS.fadeout_finished,
      DFS.fadeout_finished= 1;
      if DFS.center_visible,
        DFE= fbset(DFE, DFS.H.center, 'Visible','on');
      end
      DFE= fbset(DFE, DFS.H.msg, 'Visible','off', 'Color',[0 0 0]);
    end
  end
  DFS.timer= DFS.timer + time_since_lasttick;
end

DFS.stopwatch= DFS.stopwatch + time_since_lasttick;

if DFS.no~=20,
  ud= get(DFS.HH.cursor, 'UserData');
  if DFS.x<0,
    iDir= 1;
  else
    iDir= 2;
  end
  switch(opt.classes{iDir}),
   case 'left',
    DFE= fbset(DFE, DFS.H.cursor, 'XData',ud.xData - abs(DFS.x), 'YData',ud.yData);
   case 'right',
    DFE= fbset(DFE, DFS.H.cursor, 'XData',ud.xData + abs(DFS.x), 'YData',ud.yData);
   case {'down','foot'},
    DFE= fbset(DFE, DFS.H.cursor, 'YData',ud.yData - abs(DFS.x), 'XData',ud.xData);
   case {'up','tongue'},
    DFE= fbset(DFE, DFS.H.cursor, 'YData',ud.yData + abs(DFS.x), 'XData',ud.xData);
   otherwise,
    error(sprintf('unknown value for opt.classes: <%s>', ...
                  opt.classes{iDir}));
  end
end

DFE= fbset(DFE, '+');
data_feedback.state= DFS;
data_feedback.event= DFE;
