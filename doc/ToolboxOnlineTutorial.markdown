Online Tutorial 
========

### A First Glance at the Functioning of BBCI\_APPLY

The core of the BBCI online system is the function
`bbci_apply`{.backtick}.

    bbci_apply(bbci);

All information that is necessary for data acquisition and processing as
well as feeding the feedback application is stored in the struct
`bbci`{.backtick}. In principle, you can use any way you like to setup
the `bbci`{.backtick} variable. In a moment, we will see the default way
via `bbci_calibrate`{.backtick} to setup `bbci`{.backtick} from given
training data using a specified procedure. But `bbci`{.backtick} can
also be obtained from any seölf-made script, or loaded from a pretrained
file, e.g.,

    cfy_dir= [EEG_RAW_DIR 'subject_independent_classifiers/vitalbci_season2/'];
    bbci= load([cfy_dir 'kickstart_vitalbci_season2_C3CzC4_8-15_15-35']);

The details of the struct `bbci`{.backtick} are explained
[here](ToolboxOnlineBbciApplyStructure.html).
But also with a pretrained `bbci`{.backtick} classifier, still some
fields might need to be specified, e.g., from which hardware device
signals are acquired.

    bbci.source.acquire_fcn= @bbci_acquire_bv;
    bbci.source.acquire_param= {struct('fs', 100)};

Side remark: it is also possible to specify that the EEG signals are
automatically recorded:

    bbci.source.record_signals= 1;
    bbci.source.record_basename= 'imag_fbarrow_kickstart';

In this case, the BrainVision Recorder would be called to record the
signals (due to the setting of `bbci.source.acquire_fcn`{.backtick}).
But by defining

    bbci.source.record_param= {'internal',1};

and internal function is used for recording the signals, which can
therefore be used for any neuroimaging hardware (for which a
`bbci_acquire_*`{.backtick} function exists, see
[here](ToolboxOnlineBbciImplementingAcquisition.html)).

Also, a pretrained classifier might be used with different kinds of
feedback, that can be specified.

    bbci.feedback.receiver= 'matlab';
    bbci.feedback.fcn= @bbci_feedback_cursor_training;
    bbci.feedback.opt= struct('trials_per_run', 40);

Furthermore, it might be useful to redefine some parameters of the
signal processing chain:

    bbci.feature.ival= [-300 0];

But these were already examples that will become really clear only
later, when the details of `bbci_apply`{.backtick} are explained. It was
meant as a first short overview of how `bbci_apply`{.backtick} will be
used.

### A Glance at the Default BBCI Calibration Procedure

As pointed out above, any procedure can be used to setup the BBCI online
system, i.e., the variable `bbci`{.backtick}. However, the typical
calibration procedure to obtain a `bbci`{.backtick} classifier (as we
will shortly call it) is the use of the function
`bbci_calibrate`{.backtick}.

    bbci= bbci_calibrate(bbci);

It is a wrapper function that provides some basic functionality, like
loading the calibration data, and calls for the actual calibration a
specified subfunction. The is a repertoire of these specified
calibration functions, but for new types of online experiments, new
functions need to be implemented, see
[here](ToolboxOnlineBbciImplementingCalibration.html).

What kind of calibration is performed, and what data files are used for
calibration is specified in the substruct `bbci.calibrate`{.backtick},
and the calibration-specific parameters can be defined in
`bbci.calibrate.settings`{.backtick}. The online system with CSP
analysis for motor imagery control can, e.g., be calibrated in the
following way:


~~~~ {#CA-737d6e37c6995450c05e639ecee85cbc9620f48b dir="ltr" lang="en"}
bbci= [];
bbci.calibrate.fcn= @bbci_calibrate_csp;
bbci.calibrate.folder= EEG_RAW_DIR;
bbci.calibrate.file= 'VPkg_08_08_07/imag_arrowVPkg';
bbci.calibrate.read_param= {'fs',100};
bbci.calibrate.marker_fcn= @mrk_defineClasses;
bbci.calibrate.marker_param= {1, 2; 'left', 'right'};

bbci.calibrate.settings.nPatterns= 2;

[bbci, data]= bbci_calibrate(bbci);
~~~~

There are a lot more calibration-specific parameters, other than
`nPatterns`{.backtick}, for which default values are chosen, if they are
not specified in `bbci.calibrate.settings`{.backtick}. A description of
those calibration-specific parameters is given in the help of each
specific calibartion subfunction. (In this case of CSP-based
calibration, you would get it with ` help bbci_calibrate_csp `).

See
[here](ToolboxOnlineForEndUsers.html)
for more detailed information about how to use the calibration procedure
interactively.

Before talking about how to write new calibration subfunctions, we have
to take a closer look at `bbci_apply`{.backtick}.

Here we show two examples of how the online processing procedures would
look in specific cases.

​1) Continuous cursor control with motor imagery. Signals are band-pass
filtered (10-14 Hz) and log-variance is calculated from the last 500ms
each time a new data packet is received. Then the classifier is applied
to the feature vector and the resulting output is send via udp to the
feedback application.


~~~~ {#CA-da41707d6bfc0d352768420810a4df33b6b26cad dir="ltr" lang="en"}
fs= 100;
[filt_b, filt_a]= butter(5, [10 14]/fs*2);
state_acquire= ACQUIRE_FCN('init', 'fs',fs);
state_filter= [];
t_start= clock;
while etime(clock, t_start) < 10*60,
  cnt_new= AQCQUIRE_FCN(state_acquire);
  [cnt_new, state_filter]= online_filt(cnt_new, state_filter, filt_b, filt.a);
  cnt= proc_appendCnt(cnt, cnt_new);
  mrk= struct('fs',cnt.fs, 'pos',size(cnt.x,1));
  epo= cntToEpo(cnt, mrk, [-500 0]);
  fv= proc_logarithm( proc_variance( epo ));
  out= apply_separatingHyperplane(LDA, fv.x(:));
  send_xml_udp('cl_output', out);
end
~~~~

​2) LRP classification. Upon keypress ('R 1'=left, 'R 2'=right) the
system predicts whether it was performed with the left or right hand.
Acquired marker positions are relative within the acquired data packet.
They are transformed into global marker positions by adding the number
of oreviously acquired samples.


~~~~ {#CA-dceea343c2f683ad4967865af21a48409ebc98bc dir="ltr" lang="en"}
state_acquire= ACQUIRE_FCN('init', 'fs',100);
while run,
  [cnt_new, mrk_new]= ACQUIRE_FCN(state_acquire);
  mrk_new.pos= mrk_new.pos + size(cnt.x, 1);
  cnt= proc_appendCnt(cnt, cnt_new);
  event= find(ismember(mrk_new.desc, {'R  1','R  2'}));
  if ~isempty(event),
    epo= cntToEpo(cnt, mrk_chooseEvents(mrk_new, event), [-1000 0]);
    fv= proc_baseline(epo, [-1000 -800]);
    fv= proc_jumpingMeans(fv, [-300 -200; -200 -100; -100 0]);
    out= apply_separatingHyperplane(LDA, fv.x(:));
    send_xml_udp('cl_output', out);
  end
end
~~~~

​3) ERP classification: The ERP response after cues are classified into
targets vs. nontargets. Here, a reference of -200 to 0 msec is used and
5 time intervals to extract ERP features. Those time intervals range up
to 800 msec post stimulus.


~~~~ {#CA-b8df24d4009e9f1f21d8bc820235b5947a025174 dir="ltr" lang="en"}
fs= 100;
ival_ref= [-200 0];
ival_cfy= [100 150; 150 200; 200 250; 250 400; 400 800];
markers= [10:49];
cnt= [];
mrk= [];
ival= [ival_ref(1) ival_cfy(end)];
ival_sa= ival/1000*fs;
state_acquire= ACQUIRE_FCN('init', 'fs',fs);
while run,
  [cnt_new, mrk_new]= ACQUIRE_FCN(state_acquire);
  mrk_new.pos= mrk_new.pos + size(cnt.x, 1);
  [cnt, mrk]= proc_appendCnt(cnt, cnt_new, mrk, mrk_new);
  time_to_check= size(cnt.x,1) + [-size(cnt_new.x,1) 0] - -ival_sa(2);
  mrkidx_to_check= find(mrk.pos>timeival_to_check(1) & mrk.pos<=timeival_to_check(2));
  event= mrkidx_to_check(1)-1 + find(ismember(mrk.desc(mrkidx_to_check), markers));
  if ~isempty(event),
    epo= cntToEpo(cnt, mrk_chooseEvents(mrk, event), ival);
    fv= proc_baseline(epo, ival_ref);
    fv= proc_jumpingMeans(fv, ival_cfy);
    out= apply_separatingHyperplane(LDA, fv.x(:));
    send_xml_udp('cl_output', out);
  end
end
~~~~

These examples would really work in this simple form. And it is more or
less what happens in `bbci_apply`{.backtick}. The main difference is
that `bbci_apply`{.backtick} stores the acquired signals in a ring
buffer (by default 10s length) and markers in a marker queue (by default
100 markers long).

(Note that the `ACQUIRE_FCN`{.backtick} in the examples is expected to
return sample position in units 'samples', while
`bbci_acquireData`{.backtick} returns marker positions in msec.)

The implementation of `bbci_apply`{.backtick} just has to put those
processing chains into a general framework.

Concept: ![bbci\_apply example
application](_static/ToolboxOnlineTutorial.png)

First realisation:


~~~~ {#CA-1d4f04b1d914b86f1610d27f959007b303ed8130 dir="ltr" lang="en"}
bbci= bbci_apply_setDefaults(bbci);
[data, bbci]= bbci_apply_initData(bbci);

while run,
  [data.source, data.marker]= ...
        bbci_apply_acquireData(data.source, bbci.source, data.marker);
  if ~data.source.state.running,
    break;
  end
  data.marker.current_time= data.source.time;
  data.signal= bbci_apply_evalSignal(data.source, data.signal, bbci.signal);
  events= bbci_apply_evalCondition(data.marker, data.control, bbci.control);
  data.control.lastcheck= data.marker.current_time;
  for ev= 1:length(events),
    data.event= events(ev);
    data.feature= ...
        bbci_apply_evalFeature(data.signal, bbci.feature, data.event);
    data.classifier= ...
        bbci_apply_evalClassifier(data.feature.x, bbci.classifier);
    data.control.packet= ...
        bbci_apply_evalControl(data.classifier.x, bbci.control, ...
                               data.event, data.marker);
    bbci_apply_sendControl(data.control.packet, bbci.feedback);
    bbci_apply_logEvent(data, bbci, 1);
  end
  [bbci, data]= bbci_apply_adaptation(bbci, data);
  run= bbci_apply_evalQuitCondition(data.marker, bbci, data.log.fid);
end
bbci_apply_close(bbci, data);
~~~~

But the requirements can be more demanding and complex:

![bbci\_apply example
application](_static/ToolboxOnlineTutorial_002.png)

For a definition of the `bbci`{.backtick} structure that would
correspond to such a classifier see
[here](ToolboxOnlineBbciExampleSuperSpeller.html).

Final Version:


~~~~ {#CA-e87a63cab7c4492869ac75b43ddc9cd1328d493c dir="ltr" lang="en"}
bbci= bbci_apply_setDefaults(bbci);
[data, bbci]= bbci_apply_initData(bbci);

run= true;
while run,
  for k= 1:length(bbci.source),
    [data.source(k), data.marker]= ...
        bbci_apply_acquireData(data.source(k), bbci.source(k), data.marker);
  end
  if ~all(cellfun(@(x)getfield(x,'running'), {data.source(:).state})),
    break;
  end
  % set current time to the minimum amount of available data
  data.marker.current_time= min([data.source.time]);
  for k= 1:length(bbci.signal),
    in= bbci.signal(k).source;
    data.signal(k)= bbci_apply_evalSignal(data.source(in), ...
                                          data.signal(k), ...
                                          bbci.signal(k));
  end
  for ic= 1:length(bbci.control),
    % if no new data is acquired for this control since last check -> continue
    src_list= bbci.control(ic).source_list;
    if max([data.source(src_list).time]) <= data.control(ic).lastcheck,
      continue;
    end
    events= bbci_apply_evalCondition(data.marker, data.control(ic), ...
                                     bbci.control(ic));
    data.control(ic).lastcheck= data.marker.current_time;
    for ev= 1:length(events),
      data.event= events(ev);
      cfy_list= bbci.control(ic).classifier;
      feat_list= [bbci.classifier(cfy_list).feature];
      for k= feat_list,
        if data.event.time > data.feature(k).time,
          signal= data.signal( bbci.feature(k).signal );
          data.feature(k)= ...
              bbci_apply_evalFeature(signal, bbci.feature(k), data.event);
        end
      end
      for cfy= cfy_list,
        fv= cat(1, data.feature(bbci.classifier(cfy).feature).x);
        data.classifier(cfy)= ...
            bbci_apply_evalClassifier(fv, bbci.classifier(cfy));
      end
      cfy_out= cat(1, data.classifier(cfy_list).x);
      data.control(ic).packet= ...
          bbci_apply_evalControl(cfy_out, bbci.control(ic), ...
                                 data.event, data.marker);
      for k= 1:length(bbci.feedback),
        if ismember(ic, bbci.feedback(k).control),
          bbci_apply_sendControl(data.control(ic).packet, bbci.feedback(k));
        end
      end
      bbci_apply_logEvent(data, bbci, ic);
    end
  end
  [bbci, data]= bbci_apply_adaptation(bbci, data);
  run= bbci_apply_evalQuitCondition(data.marker, bbci, data.log.fid);
end
bbci_apply_close(bbci, data);
~~~~

