# Analysis of Variance (ANOVA)


## Background

An analysis of variance (ANOVA) can be conceived of as a generalization of a
`t-test` to more than 2 groups and multiple factors (conditions). ANOVA makes
the following assumptions about your data distribution:

* Observations are independent
* The sample data have a normal distribution
* Homogenity of variance: data variance is equal in all groups

![{i}](_static/icon-info.png "{i}")
Repeated-measures ANOVA (RM-ANOVA) vs conventional/independent ANOVA

* In an *independent design*, all levels of all factors are different groups
  consisting of different subjects.
* In a *repeated-measures design*, all subjects participated in all condition
  (ie each subject was measured repeatedly).
* A design with both repeated and independent factors is called *mixed design*
  and you can implement it yourself using `anovan`.

![{i}](_static/icon-info.png "{i}") Extra
assumption of RM ANOVA

* Sphericity: Difference scores between levels have equal variance for all
  levels. If sphericity is violated, one can resort to Greenhouse-Geisser
  correction of the degress-of-freedom. Strictly speaking, you have to evaluate
  the sphericity assumption before you do a RM ANOVA, eg using *Mauchly's test
  of sphericity*. If sphericity is violated, you can still perform ANOVA if you
  correct the df's, eg using *Greenhouse-Geisser* correction, but somebody
  should implement this first ...

If the ANOVA omnibus test yielded a significant result, you can proceed
comparing the different levels of each factor by means of multiple comparisons.
For this, the MATLAB function `multcompare` is used.

## Further reading

* [Wikipage](http://en.wikipedia.org/wiki/Statistical_hypothesis_testing)
  - general introduction into statistical statistical hypothesis testing
* [Wikipage on ANOVA](http://en.wikipedia.org/wiki/Analysis_of_variance)
* Cohen H. Explaining Psychological Statistics (BBCI library)

## Toolbox

* `rmanova` `(BBCI)`
* `nested2multidata` `(BBCI)`
* `multcompare`

To perform an ANOVA or RM ANOVA, you can use the BBCI function `rmanova`. It
takes as first input argument `dat` which is a `(K+1)`-dimensional matrix where
`K` is the number of different factors (conditions). Two sample visualizations
of the data matrix:

![ANOVA results](_static/ToolboxStatisticalAnova.png "ANOVA results")

In other words, the *first dimension* (rows) lists the subjects. The second
dimension represents the levels of the first factor, the third dimension the
levels of the second factor, and so on. For instance, taking the rightmost data
structure in the illustration, then `dat(10,3,2)` would access the `10th`
subject, the `3rd` level of the first factor and the `2nd` level of the second
factor.

![{i}](_static/icon-info.png "{i}") If your data contains multiple factors but
the factors are nested in the columns instead of being arranged in a `K+1`
dimensional matrix, you can use the function `nested2multidata` to convert the
data to the desired format.

Example:

```matlab
% Load ERP data
l=load([DATA_DIR 'results/studies/onlineVisualSpeller/erp_components']);

% The three factors are embedded in the 2nd dimension, need to be un-nested
nlevels = [3 2 3]; % Specify fastest varying levels first (Electrode)
dat = nested2multidata(l.amp,nlevels);
% Perform 3-way repeated-measures ANOVA
[p,t,stats,terms,arg] = rmanova(dat,{'Electrode'  'Status'  'Speller'});
```

The result is also displayed in a pop-up figure where `Prob>F` gives the
*p*-values.

![ANOVA results](_static/ToolboxStatisticalAnova_003.png)

![\<!\>](_static/attention.png "<!>") An easy way to extract ERP amplitudes and
latencies is the BBCI function `erp_components`.

After an omnibus test such as ANOVA yielded significant results, one can proceed
using post-hoc tests. When your factor has more than 2 levels, ANOVA tells you
that there is *a difference somewhere*. With post-hoc tests, multiple pair-wise
comparisons are performed in order to find out *which* levels are different from
each other. Technically, post-hoc tests are similar to a t-test but with a
correction in order to prevent an inflation of the [Type I
error](http://en.wikipedia.org/wiki/Type_I_and_type_II_errors#Type_I_error).
*Tukey-Kramer, Dunn-Sidak, Bonferroni, and Scheffe* are some well-known post-hoc
tests.


```matlab
% Tukey-Kramer post-hoc test
comp = multcompare(stats,'estimate','anovan','dimension',[4 ]);
```

where `dimension` specifies over which dimension (factor) the means should be
calculated. Multiple dimensions can be specified. Note that `Subject` is now the
first dimension, so if you want to specify the first factor, dimension should be
`2`. The result is a pop-up window, with the different levels on the y-axis and
the corresponding means on the x-axis. By clicking on a level you can see
whether or not it is significantly different from the other levels.

![ANOVA  Multicomparison](_static/ToolboxStatisticalAnova_002.png)

## M-file

[anova\_tutorial.m](_static/anova_tutorial.m)

## Author(s)

Matthias Treder
[matthias.treder@tu-berlin.de](mailto:matthias.treder@tu-berlin.de)

