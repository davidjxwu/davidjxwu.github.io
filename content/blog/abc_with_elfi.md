---
title: "ABC of a deterministic model with ELFI"
date: '2023-05-17'
tags: ['stats']
---

Recently, I've been playing with ABC libraries to do estimation of parameters for some models we're investigating to fit some temporal data. ABC (approximate Bayesian computation) attempts to generate samples that have distribution approximately like a target posterior, where the likelihood function is intractable. Instead, it uses some measure of distance between summary statistics of the generating process and the data in order to select samples.
For our application, this is useful, since we can construct measures of distance between the model and the data, but we don't really have a good idea of what the likelihood function can even be represented by.

There seem to be a large number of libraries out there that purport to provide an interface for ABC, but of the few I've tried, many do not have easy-to-implement interfaces for mechanistic models.
As a relative newcomer to likelihood-free inference, it was critical for me to be able to adapt "existing" code to the ABC framework, and then have the library do a large amount of heavy lifting in terms of the algorithms used for sampling.

Here, I'll detail a minor success I've had fitting a toy SIR ODE model with a Poisson observation model on the prevalence.

## The Library

We're using ELFI, a Python library written by [Lintusaari et al.](https://www.jmlr.org/papers/v19/17-374.html). The docs are [here](https://elfi.readthedocs.io/en/latest/).

The reason we're using this library are:
- It has a relatively lightweight interface for defining the necessary components for ABC sampling
- It has a good range of sampling algorithms that reduce the burden of knowledge on the user (e.g. adaptive threshold selection)
- I got it to work (!)

## The Mechanistic Model

```python
import numpy as np
from scipy import integrate

def sir_ode(t, y, beta, alpha):
    """SIR model (RHS), adapted to generate N samples (dictated by the sizes of y, beta, alpha)"""

    # reshape and split inputs by the batch
    # y is the state vector, comes in shape (3N,)
    # beta, alpha each come in shape (N,)
    y = np.clip(y, 0, None)
    S, I, R = np.asanyarray(y).reshape((-1, 3)).T
    beta = np.asanyarray(beta).flatten()
    alpha = np.asanyarray(alpha).flatten()

    dydt = [
        -beta*S*I,
        beta*S*I - alpha*I,
        alpha*I,
    ]
    return np.vstack(dydt).T.flatten()

def process(parameters, tgrid, batch_size=1):
    """The underlying model, abstracted for calling with just the parameters"""

    tbounds = min(tgrid), max(tgrid)
    
    # we are not estimating the initial state
    initial_state = np.array((9_999, 1, 0)) / 10_000 
    init_N = np.tile(initial_state.reshape((1, 3)), (batch_size, 1)).flatten()
    
    sol = integrate.solve_ivp(sir_ode, tbounds, init_N, args=[*parameters], t_eval=tgrid)
    soly = sol.y.reshape((batch_size, 3, -1))
    return soly[:, 1, :] * 10_000

def simulator(R0, rec, batch_size=1, random_state=None):
    """Observation model"""

    # define observation times (uniform time grid)
    NGRID = 101
    tgrid = np.linspace(0, 100, NGRID)

    # transform parameters
    beta = np.asanyarray(R0)/np.asanyarray(rec)
    alpha = 1/np.asanyarray(rec)

    # solve ODE
    underlying_process = process((beta, alpha), tgrid, batch_size=batch_size)
    underlying_process[underlying_process < 1e-16] = 1e-16   # fudge positivity

    return stats.poisson.rvs(underlying_process, 
                             size=(batch_size, NGRID), 
                             random_state=random_state)
```

Nothing too fancy for the mechanistic model: we're just using the simple SIR model, and observing the prevalence via a Poisson observation model. The SIR model is solved non-dimensionally, and then made dimensional before the observation process. We do not attempt to estimate the initial conditions - these are simply provided to the integrator, though estimating these probably wouldn't be difficult to implement (but the nonidentifiability might kill the sampling step). One other small note is that we will use $R_0$ and the recovery period as our parameters of interest. This just allows us to ensure that $R_0 > 1$ so that we will always have an outbreak. We also put in a (numerical) lower bound on our state variables so that we don't run into computational issues when running the ODE solver with parameters that encourage rapid dynamics.

One oddity that you will see quickly is the handling of a `batch_size` parameter. This is a quirk that I think is unique to ELFI. ELFI likes it when you can rapidly generate a large number of samples. It does this by expecting the simulator to be able to create an arbitrary number of samples.
For our purposes, we simply allow for this by stacking the multiple ODEs on top of each other. This _does_ introduce performance penalties in terms of the adaptive step control being overly conservative (intuitively we get a "slowdown" in step size when one of the realisations goes through the exponential growth phase, which has different timings for different $R_0$).

We can simulate an arbitrary number of realisations like so:

```python
from matplotlib import pyplot as plt

N = 128
R0s_example = np.random.uniform(1, 10, N)
recs_example = np.random.uniform(0.05, 20, N)

realisations = simulator(R0s_example, recs_example, batch_size=N)

plt.figure()
plt.plot(np.linspace(0, 100, 101), realisations.T, color='k', alpha=0.3, linewidth=0.5)
plt.xlabel("time, t")
plt.ylabel("prevalence, y")
```

![Plot of realisations](/images/blog/elfi/mech_realisations.png)

## The Statistical Model

```python
import elfi

theta_true = {'R0': 2, 'rec': 7}
theta_true_vec = [theta_true['R0'], theta_true['rec']]
data_y = simulator(*theta_true_vec)

model = elfi.ElfiModel()
R0_prior = elfi.Prior('uniform', 1, 9, model=model, name='R0')
rec_prior = elfi.Prior('uniform', 0.05, 19.95, model=model, name='rec')
sim_engine = elfi.Simulator(simulator, model['R0'], model['rec'], observed=data_y, name='SimEngine')
summary_stat = elfi.Summary(lambda x: x, sim_engine, name='summary')
distance = elfi.Distance('euclidean', summary_stat, name='dist')
```

That's all the boilerplate and definitions needed to construct a working model in ELFI. Pretty concise, though it depends on the legwork we did above.
Here, we're generating a single realisation with known parameters to use as synthetic data for fitting.
In the next block, we define priors on the parameters of interest, define the simulator, summary statistic(s) and the distance measure. These are all very naïve choices -- not ideal in any sense, but they'll do for an example.

## Sampling

```python
sampler = elfi.AdaptiveThresholdSMC(model['dist'], batch_size=1000, q_threshold=0.995)
result = sampler.sample(2000, max_iter=5)
```

Here, I don't have a good idea of what a "good" distance to accept is, so I choose to use an adaptive threshold sampler that automatically tunes the threshold of acceptance on the distance between iterations. How it does this is beyond my understanding, but the way it does this by targeting the `q_threshold` parameter.

The ELFI library provides a way to view a summary of the samples generated, and a method to plot them:

```python
print(result)
```

```
Method: AdaptiveThresholdSMC
Number of samples: 2000
Number of simulations: 313000
Threshold: 391
Parameter                Mean               2.5%              97.5%
R0:                     2.008              1.982              2.034
rec:                    7.038              6.886              7.189
```

```python
plt.figure()
result.plot_pairs(all=True)
```

![First population of samples](/images/blog/elfi/pop_0.png)
![Second population of samples](/images/blog/elfi/pop_1.png)
![Third population of samples](/images/blog/elfi/pop_2.png)
![Fourth population of samples](/images/blog/elfi/pop_3.png)
![Fifth (final) population of samples](/images/blog/elfi/pop_4.png)

Not too shabby.