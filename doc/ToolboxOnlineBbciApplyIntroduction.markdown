# BBCI Online System - Introduction to `bbci_apply`

## The General Scheme

The matlab function `bbci_apply.m` is used for the following loop: acquire data
from a neuroimaging source (EEG, NIRS), apply preprocessing and extract
features, apply a classifier and transform the output into a control signal
which is sent to an application. The input to `bbci_apply.m` is a structure that
specifies the preprocessing, feature extraction and classification. All
parameters, like time intervals and weights of the classifier are stored in that
structure. Before going into details, here is the (simplified) general structure
in pseudo code:

```matlab
while run:
   acquire data
   apply preprocessing and store continuous signals into a buffer
   check whether a control output should be generated (e.g., triggered by a marker)
   for each control event:
      get segment from buffer
      extract feature
      apply classifier
      transform into a control signal
      send control signal to application
   end
   check quit condition
end
```

This corresponds to the following figure:

![bbci\_apply example
application](_static/ToolboxOnlineBbciApplyIntroduction_002.png)


## An example instant of a specific online processing

For a more tangible introduction, here is are two examples of how the online
processing procedure would look in specific cases

**First case: Continuous cursor control with motor imagery.** Signals are
band-pass filtered (10-14 Hz) and log-variance is calculated from the last 500ms
each time a new data packet is received. Then the classifier is applied to the
feature vector and the resulting output is send via udp to the feedback
application.

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

**Second case: LRP classification.** Upon keypress ('R 1'=left, 'R 2'=right) the
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

**Third case: ERP classification:** The ERP response after cues are classified
into targets vs. nontargets. Here, a reference of -200 to 0 msec is used and 5
time intervals to extract ERP features. Those time intervals range up to 800
msec post stimulus.

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

Of course, we do not want to write a new `bbci_apply` for each type of
processing, so we need a general framework. The procedure of preprocessing and
classification is specified beforehand, and the required parameters are
determined from calibration data, and everything is store in a variable that is
called `bbci`. (Furthermore, for the real `bbci_apply` we would not like to have
`cnt` grow forever, but use a ring buffer of say 10s.)


## The Data Flow

The function `bbci_apply` for online operation is structured in modules:
`source`, `signal`, `feature`, `classifier`, `control`, `feedback`. The names
correspond to both, one link in the chain of processing steps, and format in
which data is temporarily stored. In the function `bbci_apply`, the processing
chain is specified in a struct `bbci`, and data is temporarily stored in the
struct `data`. The following figure illustrates the data formats, and the
processing steps that transform the data from one link to the next:

![bbci\_apply example application](_static/ToolboxOnlineBbciApplyIntroduction_003.png)


## The variable `bbci`

The processing/classification etc is specified in the variable `bbci`. This is
the input to the function `bbci_apply.m` and it is static. (It is just modified
in the very beginning of `bbci_apply.m` by the function `bbci_apply_setDefaults`
to fill missing fields with default values.) The variable `bbci` is typically
generated by the script `bbci_calibrate` from calibration data. See also the
demos in `online/demos/` where some examples for `bbci` structures are defined
from the scratch. The data structures are explained in more detail in
`bbci_apply_structures.m` and [here](ToolboxOnlineBbciApplyStructure.markdown).


Field            Description
---------------- -----------------
.source          defines the sources from which signals are acquired (may to multiple, e.g., EEG+NIRS)
.marker          defines how markers are stored
.signal          defines how the continuous signals are preprocessed after acquisition and before cutting out segments, and how signals are stored
.feature         extraction of features from segments of continuous data
.classifier      specifies which classifier is applied to the features
.control         defines a function that transforms the classifier output into a control signal (may include averaging across ERPs and early stopping)
.feedback        specifies where the control signal is transmitted to (e.g., via UDP to pyff)
.adaptation      specifies whether/how classifer/feature extraction etc should be adapted
.log             specifies what information should be logged and how (screen or file)
.quit_condition  specifies under which condition bbci_apply should stop

## The variable `data`

The variable `data` is an internal variable of `bbci_apply.m` which stores all
intermediate information. There is a strong correspondence between the fields of
`bbci` and the fields of `data`.


Field of Data  Purpose
-------------- -----------------
.source        short term input buffer (default 40ms), information about acquisition source (state), e.g., channels and sampling frequency which is obtained when initializing
.marker        buffer for markers (default for 100 events)
.signal        mid term (ring) buffer of preprocessed, continuous signals (default 10s)
.feature       extracted features for the current event (old features are not buffered)
.classifier    output of the classifier(s)
.control       control signal
.log           id and name of the log file (if logging is on)


## A simplified `bbci_apply.m`

A simple version of `bbci_apply.m` would look like this:

```matlab
bbci= bbci_apply_setDefaults(bbci);
data= bbci_apply_initData(bbci);
run= true;
while run,
  [data.source, data.marker]= bbci_apply_acquireData(data.source, bbci.source, data.marker);
  data.signal= bbci_apply_evalSignal(data.source, data.signal, bbci.signal);
  events= bbci_apply_evalCondition(data.marker, data.control, bbci.control);
  for ev= 1:length(events),
    data.event= events(ev);
    data.feature= bbci_apply_evalFeature(data.signal, bbci.feature, events(ev));
    data.classifier= bbci_apply_evalClassifier(data.feature, bbci.classifier);
    data.control= bbci_apply_evalControl(data.classifier, bbci.control, data.event, data.marker);
    bbci_apply_sendControl(data.control, bbci.feedback);
  end
  bbci= bbci_apply_adaptation(data, bbci);
  data= bbci_apply_resetData(data);
  run= bbci_apply_evalQuitCondition(data.marker, bbci);
end
```

The segmentation of continuous data into epochs is specified in two different
fields of `bbci`. The subfield `condition` of `control` defines under which
condition the control is determined (and send to the application). This may
either happen for each block of acquired data (i.e., unconditioned) as for
continuous cursor control, or depending on the occurrence of specified markers
as for ERP-based feedbacks. In the first case the last acquired sample is the
reference time, and in the latter case the timepoint of the marker is the
reference time. The subfield `ival` of `feature` specifies the time interval
relative to that reference time, for which the epoch is cut out from the
continuous signals.

That's in principle all - simple and clear. Also the subfunctions
`bbci_apply_*.m` which are called are rather simple. So, don't be afraid of
`bbci_apply.m`.


## Requirements for having it a bit more general

Granted it has to be a bit more complex in order to be general, but also the
final version of `bbci_apply.m` is not much more complicated. The idea of having
a more general structure is the following. We might like to acquire data from
different sources simultaneously, e.g., EEG and NIRS or EEG and Eye Tracker.
Further more we might use different features, like LRP and ERD for motor tasks.
And we might need to generate different kinds of control signals, e.g., P300
detection and *error potential* detection.

In order to make the requirements for a more complex online scenario clear, here
is a figure of a conceivable application. It is a attention-based speller
(exploiting attention specific modulations of ERPs and ERDs) which has an
automatic rejection of false selections based on the error potential, and which
adapts to the current state of vigilance.

![bbci\_apply example application](_static/ToolboxOnlineBbciApplyIntroduction.png)

## Consequences for the data structures

The following fields of `bbci` may be struct **arrays**:

**`source`**: there may be different sources from which signals are acquired  
**`signal`**: each signal may have input only from one source, since sources may have different sampling rates  
**`feature`**: each feature may have input only from one `signal`  
**`classifier`**:  each classifier may have input from several features; features (as column vectors) are concatenated  
**`control`**: each control may have input from several classifiers; classifier outputs (as column vectors) are concatenated  
**`feedback`**: each feedback may have input from several controls

Accordingly, also the following fields of data are arrays: `source`, `signal`,
`feature`, `classifier`, `control`. All those fields are struct arrays. Since
features may be used by different classifiers, the function tries to avoid
recalculation.

For a definition of the `bbci`structure that would correspond to such a
classifier see [here](ToolboxOnlineBbciExampleSuperSpeller.markdown).

The details of the struct `bbci` are explained
[here](ToolboxOnlineBbciApplyStructure.markdown).


## The final version of `bbci_apply.m`

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
