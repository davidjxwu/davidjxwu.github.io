---
title: "Accelerating Multinomial Sampling with Numba"
date: '2024-04-03'
tags: ['python']
---

So I was converting some random sampling in my simulation code to incorporate a new constraint. This imposed a new structure on a collection of random variates that were previously independently sampled.
Luckily this new structure could be solved using a combination of an initial independent sample plus a multinomial random variate sample. The code roughly looked like:

```python
import numpy as np
rng = np.random.default_rng()

N = 300
Q = 80_000

movement_rate = np.array(shape=(N, 1))
movement_probability_matrix = np.array(shape=(N, Q))

number_of_individuals_moving = rng.poisson(movement_rate).flatten()
places_individuals_move_to = rng.multinomial(
    number_of_individuals_moving, 
    movement_probability_matrix
)
```

## The problem 

Implementing this, I noticed that the simulation time was significantly longer than I had expected, and a profile showed me where:

![](/images/blog/multinomial/burn_chart.png)

(I'll stick some notes about generating this sort of diagram at the bottom)

It looked like the multinomial sample was very expensive. This wasn't surprising: I was sampling using an input array of size `~300`, and the probability matrix that mapped the outcomes was `~300x80000` (around 80,000 outcomes).

## Removing zeros

One lucky break we have is that the probability matrix is sparse: in each row, there are only a few outcomes with non-zero probability.
An initial attempt to speed this up, using standard tools was to attempt to squeeze the zeroes out of this sparse matrix. The logic is that this saves loops that iterate over these zeros which are impossible outcomes anyway. 
If we focus on the single random variate case (this will become a problem later) we have `N` trials, and want to sample the number of outcomes in `Q` bins, as dictated by a probability vector `P`. We can save some computational effort by recording the indices of `P` which have non-zeros, and only passing those non-zero values through to the multinomial sampler.

```python
non_zero_indices = np.where(P)
non_zero_values = P[non_zero_indices]

sampled_values = rng.multinomial(N, non_zero_values)
actual_values = np.zeros(Q)
actual_values[non_zero_indices] = sampled_values
```

In the case where `P` is a `scipy.sparse.csr_matrix`, we can actually get this information pretty directly:

```python
non_zero_indices = P.indices
non_zero_values = P.data
...
```

The problem is of course the extension to the case where we consider a vector `V` of trials, and have a matrix `P` instead.
We then have to either consider only non-zero columns, which is expensive to extract, and doesn't save as much; or transform the problem into a sequence of 1D problems by going row-by-row.
Neither of these approaches saves enough time for us to be in a regime where using this code is feasible.

## JIT Tools

The sequential row-by-row approach _does_ have some merit though. If we can make the loop and its components fast(er than Python), we could have a good solution. Luckily, we do have such a solution: there are a range of JIT libraries that can accelerate our code by precompiling parts of our code "just in time". I've been aware that these libraries exist, but they have historically scared me because of their limitations - they assume some sort of rigid structure of the data, which makes doing certain things difficult. However, the benefits are certainly very appealing: recently I watched a [Youtube video](https://youtu.be/umLZphwA-dw) by [Doug](https://www.youtube.com/@dougmercer) [Mercer](https://www.dougmercer.dev/) where a simple toy problem was brought to as-fast-as-C speeds. Considering we have a single bottleneck of a relatively tightly-scoped problem, we could have a look at some of these solutions.

[Taichi](https://www.taichi-lang.org/) is a very appealing library that has in-built GPU acceleration. The only problem with Taichi is that I would struggle find a nice mapping from my native Python objects to Taichi domain language objects, which are required to interact and thus benefit from the library in any way. Architecturally, this would require a decent amount of overhead and rewriting that may not be feasible in a short turnaround time with a reasonably long learning curve.

So instead, I opted to use [numba](https://numba.pydata.org). Numba also does have some limitations, but it requires very little boilerplate and rearchitecturing of code.
In an ideal world, I'd be able to 