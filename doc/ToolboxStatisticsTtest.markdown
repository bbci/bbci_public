# T-test


## Background

With a **t-test** one can investigate whether two collections of samples stem
from different underlying populations. For instance, one can investigate whether
P3 peaks in two experimental conditions are significantly different. The t-test
is a *parametric test*, i.e. it assumes that data have come from a Gaussian
probability distribution and make inferences about the parameters of the
distribution. Assumptions of the t-test:

* Population data from which the sample data are drawn are normally distributed.
* The variances of the populations to be compared are equal.

![{i}](_static/icon-info.png "{i}") Paired-samples versus independent-samples
t-test

* In the paired-samples test with two conditions, the assumption is that all
  samples have been drawn pair-wise. In a typical BCI experiment, this means
  that every subject participated in condition 1 and condition 2. In other
  words, the samples in the two conditions are paired by the subjects.
* In the independent samples test, the assumption is that all samples have been
  drawn independently. In a typical BCI experiment, this would mean that there
  are two groups of subjects. Group A was tested in condition 1, group B was
  tested in condition 2.
* If applicable, the paired-samples is to be preferred because it accounts for
  the inter-subject variability and thus increases statistical power.

![\<!\>](_static/attention.png "<!>") Some pitfalls

* Reaction times are *not* Gaussian-distributed. They have a skewed long-tail
  distribution. Therefore the *arithmetic mean* is not a good estimator of the
  mean. Use either the *geometric mean* (`geomean()` in Matlab) or calculate the
  reciprocal of reaction time, `speed = 1/RT`, which gives a more symmetric
  distribution and allows for the calculation of the arithmetic mean.
* If a test does not yield a significant result (i.e., *p* \> α), this does *not
  necessarily* mean that the distributions are the same. Measurements might not
  be accurate enough (when the difference between the distributions is subtle)
  or the number of data samples might be too small. The only thing you can say
  is that the distributions are not different.

## Further reading

* [Statistical hypothesis testing](http://en.wikipedia.org/wiki/Statistical_hypothesis_testing)
  - general introduction
* [Wikipage on t-test](http://en.wikipedia.org/wiki/Student%27s_t-test)
* Cohen, Barry. (1996)  Explaining psychological statistics. Belmont, CA, US:
  Thomson Brooks/Cole Publishing Co..

## Toolbox

* `ttest`
* `ttest2`

If two conditions are compared, your data matrix is a Nx2 matrix. In a
paired-samples t-test, the N subjects are arranged along the rows, with the
first column corresponding to condition 1 and the second column corresponding to
condition 2. In an independent-samples t-test, each column represents one group
consisting of N subjects each; there is no specific order for the subjects in
the two groups. This can be visualized as follows.

![t-test](_static/ToolboxStatisticsTtest.png)

The following code gives an example on performing a paired-samples t-test in
Matlab. First, two Gaussian distributed data columns are generated in `d`. Then,
they are compared to each other using a t-test.


```matlab
N = 20;
d = [randn(N,1) randn(N,1)+0.1];      % Each column is one dataset
[h,p,ci,stats] = ttest(d(:,1), d(:,2))
```

where `h` (0 or 1) specifies whether or not the null hypothesis "*The means of
the two distributions are equal*" is rejected, `p` gives the according
*p*-value, `ci` gives an 1-α confidence interval for the `d1-d2` mean. `stats`
is a struct giving the *t*-value, the degrees-of-freedom `df`, and the standard
deviation `sd`.

You can also run a one-sample t-test on each of the two distributions, using


```matlab
[h,p,ci,stats] = ttest(d(:,1))
[h2,p2,ci2,stats2] = ttest(d(:,2))
```

In this case, the t-test tests whether the mean of each distribution is
significantly different from 0.

For an *independent-samples t-test*, the MATLAB code is virtually identical, but
to use the MATLAB function `ttest2`

```matlab
[h,p,ci,stats] = ttest2(d(:,1),d(:,2))
```

## M-file

[ttest\_tutorial.m](_static/ttest_tutorial.m)

## Author(s)

Matthias Treder
[matthias.treder@tu-berlin.de](mailto:matthias.treder@tu-berlin.de)

