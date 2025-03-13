---
title: "Pseudolikelihood"
date: "2023-06-29"
categories: ["statistics"]
draft: yes
math: true
---

I ran into an odd problem recently. I was trying to fit a model, where the state is observed through a negative binomial distribution. This shouldn't be a difficult task, you may exclaim - and that is true. Many libraries, in many different programming languages, provide utilities for doing this, which appropriately transform the data and perform your estimation procedure of choice.
Of course, I had to make life hard on myself, and implement a slightly wonky method from scratch - glueing together the disparate basic numerical algorithms and procedures together. And therein lies the problem: when one of those components imposes an odd restriction.

## The Problem Setup

Let's briefly cover the problem first. I have some model $f$ of the underlying "true" state $x$, which depends on parameters $\theta$:

$$x(t) = f(t; \theta).$$

I then have observations $y$ through a negative binomial error model:

$$\begin{gathered}
y \sim \text{NegBin}(r, p(t)) \newline\\ 
p(t) = \frac{r}{r + x(t)}
\end{gathered}$$

$y$ has the PMF:

$$\text{PMF}(y(t_i); x(t_i), r) = \frac{\Gamma(r + y_i)}{\Gamma(r) + \Gamma(y_i+1)} p^r (1-p)^{y_i}.$$

For this blog, we will just attempt to use this PMf as the likelihood, and perform inference based on the likelihood only.

## Running Example: Data

As a running example, let's use this model for $f$:

$$x(t) = \exp(\theta t)$$

and use ground truth parameters $\theta = 5, r = 10$.

We can generate a realisation of the data in Python:

```python
import numpy as np

rng = np.random.default_rng(0x12b342b71)

N = 41
ts = np.linspace(0, 1, 41)
def f(p):
    return np.exp(p * ts)
p_true = 5
r_true = 10
xs = f(p_true)
ys = rng.negative_binomial(r=r_true, p=(r_true/(r_true + xs)))
```

Plotting this gives:

![A realisation of observations from the model](/images/blog/pseudoll/data.png)

We see that, true to negative binomial form, that the variance of the error between the data $y$ and the underlying state $x$ is an increasing function of the value of the state.

## Solving for the MLE

Solving the statistical problem isn't difficult. We simply can maximise the likelihood given the data (or typically minimise the negative log-likelihood).

We can do this in Python with a few function definitions:

```python
from scipy.special import loggamma
from scipy import optimize

def negbin_neg_log_likelihood(y, x, r):
    p = r / (r + x)
    c = loggamma(r + y) - loggamma(r) - loggamma(y + 1)
    loglik = c + r * np.log(p) + y * np.log(1-p)
    return -np.sum(loglik)

def objective_function_true_log_lik(ps):
    theta, r = ps
    x = f(theta)
    return negbin_neg_log_likelihood(ys, x, r)

max_lik_est = optimize.minimize(objective_function_true_log_lik, x0=[p_true, r_true])
```
Here, we'll give the optimisation algorithm the benefit of the doubt, and start it at the truth.

The captured output looks like:

```html
<snip>
      fun: 266.5628227424429
        x: [ 4.979e+00  6.106e+00]
</snip>
```

## The Issue

This is all well and good, but I'm not implementing in numpy, since it makes computing the derivative of the log-likelihood function (the function we pass into the optimisation algorithm) very difficult if we have a non-standard model. For example, if the model doesn't have a closed-form solution, we will be in trouble (either mathematically, or in a manager-breathing-down-your-neck sort-of way).
So, we use an automatic differentiation framework, like [CasADi](https://web.casadi.org), to actually implement our models and statistical methods.
This is all very well and good, _except_
**CasADi doesn't implement a gamma function.**
And that leaves us in a bit of a pickle, because the likelihood function above relies on a normalising factor (denoted `c` in the code) that is computed via the gamma function. This means we can't estimate $r$ using the "direct" approach, since the noramlising factor depends on it.

## Pseudolikelihood


