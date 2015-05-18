# BBCI Online Tutorial 

### A First Glance at the Functioning of BBCI_APPLY

The core of the BBCI online system is the function `bbci_apply`.

```matlab
bbci_apply(bbci);
```

All information that is necessary for data acquisition and processing as well as
feeding the feedback application is stored in the struct `bbci`. In principle,
you can use any way you like to setup the `bbci` variable. In a moment, we will
see the default way via `bbci_calibrate` to setup `bbci` from given training
data using a specified procedure. But `bbci` can also be obtained from any
self-made script, or loaded from a pretrained file, e.g.,

```matlab
cfy_dir= [EEG_RAW_DIR 'subject_independent_classifiers/vitalbci_season2/'];
bbci= load([cfy_dir 'kickstart_vitalbci_season2_C3CzC4_8-15_15-35']);
```

The details of the struct `bbci` are explained
[here](ToolboxOnlineBbciApplyStructure.markdown). But also with a pretrained
`bbci` classifier, still some fields might need to be specified, e.g., from
which hardware device signals are acquired.

```matlab
bbci.source.acquire_fcn= @bbci_acquire_bv;
bbci.source.acquire_param= {struct('fs', 100)};
```

Side remark: it is also possible to specify that the EEG signals are
automatically recorded:

```matalb
bbci.source.record_signals= 1;
bbci.source.record_basename= 'imag_fbarrow_kickstart';
```

In this case, the BrainVision Recorder would be called to record the signals
(due to the setting of `bbci.source.acquire_fcn`). But by defining

```matlab
bbci.source.record_param= {'internal',1};
```

and internal function is used for recording the signals, which can therefore be
used for any neuroimaging hardware (for which a `bbci_acquire_*` function
exists, see [here](ToolboxOnlineBbciImplementingAcquisition.markdown)).

Also, a pretrained classifier might be used with different kinds of feedback,
that can be specified.

```matlab
bbci.feedback.receiver= 'matlab';
bbci.feedback.fcn= @bbci_feedback_cursor_training;
bbci.feedback.opt= struct('trials_per_run', 40);
```

Furthermore, it might be useful to redefine some parameters of the signal
processing chain:

```matlab
bbci.feature.ival= [-300 0];
```

But these were already examples that will become really clear only later, when
the details of `bbci_apply` are explained. It was meant as a first short
overview of how `bbci_apply` will be used.

### A Glance at the Default BBCI Calibration Procedure

As pointed out above, any procedure can be used to setup the BBCI online system,
i.e., the variable `bbci`. However, the typical calibration procedure to obtain
a `bbci` classifier (as we will shortly call it) is the use of the function
`bbci_calibrate`.

```matlab
bbci= bbci_calibrate(bbci);
```

It is a wrapper function that provides some basic functionality, like loading
the calibration data, and calls for the actual calibration a specified
subfunction. The is a repertoire of these specified calibration functions, but
for new types of online experiments, new functions need to be implemented, see
[here](ToolboxOnlineBbciImplementingCalibration.markdown).

What kind of calibration is performed, and what data files are used for
calibration is specified in the substruct `bbci.calibrate`, and the
calibration-specific parameters can be defined in `bbci.calibrate.settings`. The
online system with CSP analysis for motor imagery control can, e.g., be
calibrated in the following way:

```matlab
bbci= [];
bbci.calibrate.fcn= @bbci_calibrate_csp;
bbci.calibrate.folder= EEG_RAW_DIR;
bbci.calibrate.file= 'VPkg_08_08_07/imag_arrowVPkg';
bbci.calibrate.read_param= {'fs',100};
bbci.calibrate.marker_fcn= @mrk_defineClasses;
bbci.calibrate.marker_param= {1, 2; 'left', 'right'};

bbci.calibrate.settings.nPatterns= 2;

[bbci, data]= bbci_calibrate(bbci);
```

There are a lot more calibration-specific parameters, other than `nPatterns`,
for which default values are chosen, if they are not specified in
`bbci.calibrate.settings`. A description of those calibration-specific
parameters is given in the help of each specific calibartion subfunction. (In
this case of CSP-based calibration, you would get it with `help
bbci_calibrate_csp`).

See [here](ToolboxOnlineForEndUsers.markdown) for more detailed information
about how to use the calibration procedure interactively.

### Motivation of the implementation of `bbci_apply`

Before talking about how to write new calibration subfunctions, we have to take
a closer look at `bbci_apply`.

Here we show two examples of how the online processing procedures would look in
specific cases.

First case: Continuous cursor control with motor imagery. Signals are band-pass
filtered (10-14 Hz) and log-variance is calculated from the last 500ms each time
a new data packet is received. Then the classifier is applied to the feature
vector and the resulting output is send via udp to the feedback application.

```matlab
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
  epo= proc_segmentation(cnt, mrk, [-500 0]);
  fv= proc_logarithm( proc_variance( epo ));
  out= apply_separatingHyperplane(LDA, fv.x(:));
  send_xml_udp('cl_output', out);
end
```

Second case: LRP classification. Upon keypress ('R 1'=left, 'R 2'=right) the
system predicts whether it was performed with the left or right hand. Acquired
marker positions are relative within the acquired data packet. They are
transformed into global marker positions by adding the number of previously
acquired samples.

```matlab
state_acquire= ACQUIRE_FCN('init', 'fs',100);
while run,
  [cnt_new, mrk_new]= ACQUIRE_FCN(state_acquire);
  mrk_new.pos= mrk_new.pos + size(cnt.x, 1);
  cnt= proc_appendCnt(cnt, cnt_new);
  event= find(ismember(mrk_new.desc, {'R  1','R  2'}));
  if ~isempty(event),
    epo= proc_segmentation(cnt, mrk_selectEvents(mrk_new, event), [-1000 0]);
    fv= proc_baseline(epo, [-1000 -800]);
    fv= proc_jumpingMeans(fv, [-300 -200; -200 -100; -100 0]);
    out= apply_separatingHyperplane(LDA, fv.x(:));
    send_xml_udp('cl_output', out);
  end
end
```

Third case: ERP classification: The ERP response after cues are classified into
targets vs. nontargets. Here, a reference of -200 to 0 msec is used and 5 time
intervals to extract ERP features. Those time intervals range up to 800 msec
post stimulus.

```matlab
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
    epo= proc_segmentation(cnt, mrk_chooseEvents(mrk, event), ival);
    fv= proc_baseline(epo, ival_ref);
    fv= proc_jumpingMeans(fv, ival_cfy);
    out= apply_separatingHyperplane(LDA, fv.x(:));
    send_xml_udp('cl_output', out);
 end
end
```

These examples would really work in this simple form. And it is more or less
what happens in `bbci_apply`. The main difference is that `bbci_apply` stores
the acquired signals in a ring buffer (by default 10s length) and markers in a
marker queue (by default 100 markers long).

(Note that the `ACQUIRE_FCN` in the examples is expected to return sample
position in units 'samples', while `bbci_acquireData` returns marker positions
in msec.)

The implementation of `bbci_apply` just has to put those processing chains into
a general framework.

Concept: ![`bbci_apply` _example application_](_static/ToolboxOnlineTutorial.png)

First realisation:

```matlab
bbci= bbci_apply_setDefaults(bbci);
[data, bbci]= bbci_apply_initData(bbci);

run= true;
while run,
  [data.source, data.marker]= ...
        bbci_apply_acquireData(data.source, bbci.source, data.marker);
  if ~data.source.state.running,
    break;
  end
  data.marker.current_time= data.source.time;
  data.signal= bbci_apply_evalSignal(data.source, data.signal, bbci.signal);
  data.control.time= data.source.time;
  events= bbci_apply_evalCondition(data.marker, data.control, bbci.control);
  data.control.lastcheck= data.marker.current_time;
  for ev= 1:length(events),
    data.event= events(ev);
    data.feature= ...
        bbci_apply_evalFeature(data.signal, bbci.feature, data.event);
    data.classifier= ...
        bbci_apply_evalClassifier(data.feature.x, bbci.classifier);
    data.control= ...
        bbci_apply_evalControl(data.classifier.x, data.control, ...
                               bbci.control, data.event, data.marker);
    data.feedback= ...
        bbci_apply_sendControl(data.control.packet, bbci.feedback, ...
                               data.feedback);
    bbci_apply_logEvent(data, bbci, 1);
  end
  [bbci, data]= bbci_apply_adaptation(bbci, data);
  run= bbci_apply_evalQuitCondition(data.marker, bbci, data.log.fid);
end
bbci_apply_close(bbci, data);
```

This version is complete sufficient for most applications. In the toolbox, this
functions is called `bbci_apply_uni`. In can be used, when all stages of the
processing are unimodal: signals are acquired only from one device (e.g., EEG
only, not EEG+NIRS), only one type of features is calculated (e.g., only ERPs
and not both, ERPs and spectral modulations), and only one classifier is
employed.

But the requirements can be more demanding and complex:

![_bbci_apply example application_](_static/ToolboxOnlineTutorial_002.png)

For a definition of the `bbci` structure that would correspond to such a
classifier see [here](ToolboxOnlineBbciExampleSuperSpeller.markdown).

The general version of the function, `bbci_apply` can accomplish all that, but
still is not so much more complex:

```matlab
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
  % markers are expected only from source #1
  data.marker.current_time= data.source(1).time;
  for k= 1:length(bbci.signal),
    in= bbci.signal(k).source;
    data.signal(k)= bbci_apply_evalSignal(data.source(in), ...
                                          data.signal(k), ...
                                          bbci.signal(k));
  end
  for ic= 1:length(bbci.control),
    src_list= bbci.control(ic).source_list;
    data.control(ic).time= max([data.source(src_list).time]);
    % if no new data is acquired for this control since last check -> continue
    if data.control(ic).time <= data.control(ic).lastcheck,
      continue;
    end
    events= bbci_apply_evalCondition(data.marker, data.control(ic), ...
                                     bbci.control(ic));
    data.control(ic).lastcheck= data.control(ic).time;
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
      data.control(ic)= ...
          bbci_apply_evalControl(cfy_out, data.control(ic), ...
                                 bbci.control(ic), data.event, data.marker);
      for k= 1:length(bbci.feedback),
        if ismember(ic, bbci.feedback(k).control,'legacy'),
          data.feedback(k)= ...
              bbci_apply_sendControl(data.control(ic).packet, ...
                                     bbci.feedback(k), ...
                                     data.feedback(k));
        end
      end
      bbci_apply_logEvent(data, bbci, ic);
    end
  end
  [bbci, data]= bbci_apply_adaptation(bbci, data);
  run= bbci_apply_evalQuitCondition(data.marker, bbci, data.log.fid);
end
bbci_apply_close(bbci, data);
```
