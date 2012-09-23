Documentation: A Gentle Introduction to the BBCI Toolbox
========================================================

* * * * *

**UNDER CONSTRUCTION**

* * * * *

To follow this tutorial, you should have the BBCI Matlab toolbox
installed
[ToolboxSetup](ToolboxSetup.html)
and know about its data structures
[ToolboxData](ToolboxData.html).
Here, you will be animated, to explore the data structures, do some
initial analysis (e.g. plotting ERPs) manually (i.e., without using the
toolbox functions), and then see how it can be done with the toolbox.
Some the manual analysis serves the following purpose: Many of the
toolbox function are in principle simple, but the code sometimes gets
quite complicated, because it should be very general. The manual
analysis demonstrates this simplicity. So don't be afraid of the toolbox
- it's no magic.

This is a hands-on tutorial. It only makes sense, if you have it
side-by-side with a running matlab where you execute all the code.

### Table of Contents

-   Continuous data cnt:
    (ToolboxIntro <a href="#Cnt">Cnt</a>)

-   Montage defining the electrode layout: (<a href="#Mnt">Mnt</a>)

-   Marker defining certain events: (<a href="#Mrk">Mrk</a>)


-   Segmentation of the signals into epochs: (<a href="#Epo">Epo</a>)

-   Making the ERP analysis more robust: <a href="#MoreRobust">MoreRobust</a>)


-   Plot topographies and select certain time intervals: (<a href="#TopographiesAndIntervals">TopographiesAndIntervals</a>)


### Exploring the data structure <a id="Cnt"></a>

A first look at the data structure `cnt`{.backtick} which holds the
continuous (un-segmented) EEG signals.




	file= 'VPibv_10_11_02/CenterSpellerMVEP_VPibv';
	[cnt, mrk, mnt]= eegfile_loadMatlab(file);

	cnt	
	% Fields of cnt - most important are clab (channel labels), x (data) and fs (sampling rate).	
	% The data cnt.x is a two dimensional array with dimension TIME x CHANNELS.
	cnt.clab
	% This is a cell array of strings that hold the channel labels. It corresponds to the second dimension of cnt.x.
	strmatch('Cz', cnt.clab)
	% Index of channel Cz
	strmatch('P1', cnt.clab)
	% Index of channel P1? Why are there two?
	cnt.clab([49 55])
	% Ah, it matches also P10. To avoid that, use option 'exact' in strmatch
	strmatch('P1', cnt.clab, 'exact')
	% Now it works. The toolbox function 'chanind' does exact match by default:
	chanind(cnt, 'P1')
	% But it is also more powerful. And hopefully intuitive:
	idx= chanind(cnt, 'F3,z,4', 'C#', 'P3-4')
	cnt.clab(idx)
	% Be aware that intervals like 'P3-4' correspond to the rows on the scalps layout, i.e.
	% P3-4 -> P3, P1, Pz, P2, P4; and F7-z -> F7,F5,F3,F1,Fz
	% Furthermore, # matches all channels in the respective row: but C# does not match CP2.
	% (but not the temporal locations, i.e. CP# does not match TP7)
	idx= chanind(cnt, 'P*')
	% The asterix * literally matches channel labels starting with the given string.
	cnt.clab(idx)

	% Fields other than x, fs, clab are optional (but might be required by some functions).
	cnt.T
	% This is the number of time points in each run (when cnt is the contatenation of several runs).
	sum(cnt.T)
	% This should then be the total number of data points, corresponding to the first dimension of cnt.x.

	plot(cnt.x(1:5*cnt.fs,15))
	% displays the first 5s of channel nr. 15


<a id="Mnt"></a> Next, we have a look at the structure mnt, which defines the electrode
montage (and also a grid layout, but that will come later).




	mnt
	% Fields of mnt, most importantly clab, x, y which define the electrode montage.
	mnt.clab
	% Again a cell array of channel labels. This corresponds to cnt.clab. Having those information in both
	% data structure allows to match corresponding channels, even if they are in different order, or one
	% structure only has a subset of channels of the other structure.
	mnt.x(1:10)
	% x-coordinates of the first 10 channels in the two projects (from above with nose pointing up).
	mnt.y(1:10)
	% and the corresponding y coordinates.
	clf
	text(mnt.x, mnt.y, mnt.clab); axis([-1 1 -1 1])
	% displays the electrode layout. 'axis equal' may required to show it in the right proportion.
	% The function scalpPlot can be used to display distributions (e.g. of voltage) on the scalp:
	scalpPlot(mnt, cnt.x(cnt.fs,:))
	% -> topography of scalp potentials at time point t= 1s.
	% You can use this also to make a simple movie:
	for t=1000+[1:cnt.fs], scalpPlot(mnt, cnt.x(t,:)); title(int2str(t)); drawnow; end


<a id="Mrk"></a> To make sense of the data, we need to know what happened when. This is
stored in the marker data structure `mrk`{.backtick}. Markers (triggers)
are stored into the EEG signals by the program that controls the
stimulus presentation (or BCI feedback). Furthermore, markers can
triggered by a response of the participant (like button presses), or by
other sensors (visual sensors that register the flashing of an object on
a display).




	mrk
	% The obligatory fields are pos, fs, y, className, and toe. Furthermore, there can a more fields (like in this case)
	% that a specific to the experimental paradigm. These can be ignored for now.
	% The fields pos, toe and y should all the same length - corresponding to the number of acquired markers.
	% The field toe (type-of-event) code the type of event (marker number in the EEG acquisition program).
	mrk.toe(1:12)
	% E.g., toe = 16 corresponds to an 'S 16' marker. (Negative numbers correspond to BV response markers.)
	mrk.pos(1:12)
	% specifies the positions (in time) of the first 12 markers corresponding to the toe's from above. These are given
	% in the unit samples. More specifically, mrk.pos(1) = 864 corresponds to cnt.x(864,:)

	% The information given in mrk.toe maybe very detailed, more than is usually required for analysis. The most important
	% grouping is specified by mrk.y (class labels) and mrk.className (names of the classes/conditions).
	mrk.className
	% is a cell array of the class names.
	mrk.y(:,1:12)
	% Row 1 of mrk.y defines membership to class 1, and row 2 to class 2. To convert this into class numbers, you can use
	[1:size(mrk.y,1)]*mrk.y(:,1:12)
	% For most analyses, the information in mrk.y is sufficient. 
	% Here, the first class corresponds to the presentation of target stimuli. You get in indices of target markers by
	it= find(mrk.y(1,:));
	it(1:10)
	% The following displays the scalp distribution at the time point of the first target presentation:
	scalpPlot(mnt, cnt.x(mrk.pos(it(1)),:))

<a id="Epo"></a>Having the basic ingredients together, we can start a simple ERP analsis
- first manually, then with the toolbox functions.




	% segmentation of continuous data in 'epochs' based on markers
	epo= cntToEpo(cnt, mrk, [-200 800]);
	epo
	iCz= chanind(epo, 'Cz')
	plot(epo.t, epo.x(:,iCz,1))
	% This displays the first trial
	plot(epo.t, epo.x(:,iCz,2))
	% and the second
	plot(epo.t, epo.x(:,iCz,it(1)))
	% this is the first target trial
	plot(epo.t, epo.x(:,iCz,it(2)))
	% and the second.
	% The ERP of the target trials is obtained by averaging across all target trials:
	plot(epo.t, mean(epo.x(:,iCz,it),3))
	% To add the ERP of nontarget, we need to get the respective indices
	in= find(mrk.y(2,:));
	hold on
	% and plot it in the same way.
	plot(epo.t, mean(epo.x(:,iCz,in),3), 'k')

	% Visualization of ERPs with toolbox functions
	plotChannel(epo, 'Cz')
	% That should give a plot similar to the manual one.	
	% With the grid_plot function you can do that for many channels simultaneously.
	grid_plot(epo, mnt, defopt_erps)
	% Oups. For a reasonable display, we need a baseline correction:
	epo= proc_baseline(epo, [-200 0]);
	H= grid_plot(epo, mnt, defopt_erps)
	% The grid layout is also defined in the mnt structure. This is explained elsewhere.
	% Finally, we add some measure of discriminability to the grid plot:
	epo_r= proc_r_square_signed(epo);
	% r-value is the point biserial correlation coefficient, rsqs= sign(r)*r^2
	grid_addBars(epo_r, 'h_scale',H.scale);


<a id="MoreRobust"></a>The ERP analysis can be made more robust by filtering and artifact
rejection:


	% high-pass filtering to reduce drifts
	b= procutil_firlsFilter(0.5, cnt.fs);
	cnt= proc_filtfilt(cnt, b);
  
	% Artifact rejection based on variance criterion
	mrk= reject_varEventsAndChannels(cnt, mrk, disp_ival, 'verbose', 1);

	% Segmentation as before, but with high-passed cnt and cleaned mrk
	epo= cntToEpo(cnt, mrk, [-200 800]);
  
	% Artifact rejection based on maxmin difference criterion on frontal chans
	crit_maxmin= 70;
	[epo, iArte]= proc_rejectArtifactsMaxMin(epo, crit_maxmin, ...
                     'clab',{'F9,z,10','AF3,4}, 'ival',[0 800], 'verbose',1);

<a id="TopographiesAndIntervals"></a> Now we can plot some topographies and select time intervals:



	% visualization of scalp topograhies
	fig_set(1);
	scalpEvolutionPlusChannel(epo, mnt, {'Cz','PO7'}, [150:50:450], defopt_scalp_erp2);
	fig_set(2);
	scalpEvolutionPlusChannel(epo_r, mnt, {'Cz','PO7'}, [150:50:450], defopt_scalp_r);
	% refine intervals
	ival= [260 300; 350 380; 420 450; 500 540];
	scalpEvolutionPlusChannel(epo_r, mnt, {'Cz','PO7'}, ival, defopt_scalp_r2);
	fig_set(1);
	scalpEvolutionPlusChannel(epo, mnt, {'Cz','PO7'}, ival, defopt_scalp_erp2);

	% intervals can be selected automatically, based on separability values
	fig_set(3);
	select_time_intervals(epo_r, 'visualize', 1, 'visu_scalps', 1);

	% in order to extract only certain ERP component, constraints can be defined
	constraint= ...
	    {{-1, [100 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
	     {1, [200 350], {'FC3-4','C3-4'}, [200 400]}, ...
	     {1, [400 500], {'CP3-4','P3-4'}, [350 600]}};
	ival= select_time_intervals(epo_r, 'visualize', 1, 'visu_scalps', 1, ...
                            'constraint', constraint, 'nIvals',3)

