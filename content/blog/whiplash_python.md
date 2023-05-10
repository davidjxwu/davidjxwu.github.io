---
title: "A short guide to Python for mathematical epidemiology"
date: "2023-05-10"
tags: ["python", "epi"]
math: True
---

Tutorials for an entire language are impossible, even when limited in scope. Just peruse medium for examples of this.
For a "competent" programmer, it is often infuriating how meandering and unfocused these tutorials can be, while at the same time being overly specific in terms of showing off features of the language or particular libraries.
This probably won't be any different.
With that said, this is a short guide meant for scientific development, in particular for mathematical modellers working in epidemiology, or mathematical biology more generally.
I will assume basic Python familiarity.

## Installing Python

Python is very 'lenient' in allowing you to install whichever version of it you want, and lets you mix up conflicting packages together with abandon.
This results in a relatively high barrier to understanding how best to choose to interact with the system and leads to one of the various circles of dependency hell.
Typically we will need a Python interpreter, some way of managing third-party packages (a package manager), and some way of isolating sets of versions of those packages from each other (an environment manager).

The **easiest** way to proceed for a scientific developer is to use conda. There are two flavours of conda: 
- [Anaconda](https://www.anaconda.com/download) if you're a beginner and/or afraid of the keyboard (use this by default)
- [miniconda](https://docs.conda.io/en/latest/miniconda.html) if you have storage constraints and don't mind the console

Anaconda provides you with a base environment with tons of (common) libraries, and a suite of GUI tools to help. The main, shared, command-line interface is `conda`.

> Word of Caution: Python and the PATH interact strongly with each other. To avoid major problems, you should [`conda init`](https://docs.conda.io/projects/conda/en/latest/commands/init.html). This will update your shell profile to make sure it "works".

For this post, we will use a fresh environment. We will call it `tutorial_env`, and use Python 3.10.  
In a terminal:
```bash
conda create -n tutorial_env python=3.10

```

### Other Options
`conda` is always your best default bet for scientific computing. For other purposes other tools may be more useful or flexible. Here's a selection:

Interpreters:
- [Python](https://www.python.org/downloads/) by itself - technically this is all you need.
- [pyenv](https://github.com/pyenv/pyenv) manages python versions.

Package/environment managers:
- [pip](https://pypi.org/project/pip/) is the base package manager.
- [poetry](https://python-poetry.org/) is a package/dependency manager that resembles dependency managers in other languages.

## Core Libraries

The "core" of the numerical libraries in Python are:

- numpy: representation of vectors/matrices and basic mathematical functionality
- scipy: advanced or specialised mathematical/statistical functionality
- matplotlib: plotting library

For data science adjacent uses also consider:

- pandas: tabular data manipulation and computation
- scikit-learn: machine learning library
- jupyter: interactive notebooks

Some pet libraries:

- ipython: a better interactive console
- polars: an alternative tabular data library
- sympy: symbolic computation

## Examples

### Basic array manipulation

```python
import numpy as np

## Initialising arrays
# a 1D array
arr_1d = np.array([1, 2, 3, 4, 5, 6])

# a 2D array, 2 by 4 (arrays initialise by rows)
arr_2d = np.array([
    [1, 2, 3, 4],
    [5, 6, 7, 8],
])

## Generating arrays
# a 10 by 4 array of zeros
arr_zeros = np.zeros((10, 4))

# a 5 by 12 array of ones
arr_ones = np.ones((5, 12))

# a 1D array: [0, 1, 2, 3, 4, 5]
# similar to base Python range()
arr_range = np.arange(6)

## Array Operations
arr_a = np.array([
    [1, 2, 3, 4],
    [5, 6, 7, 8]
])

arr_b = np.array([
    [-1, 3, 4],
    [5, -6, 0],
    [2, 9, 8],
    [0, -4, -7],
])

arr_c = np.array([
    [4, 2, 3, 1],
    [2, 4, 1, 3]
])

# adding 
arr_a_plus_c = arr_a + arr_c
arr_a_subt_c = arr_a - arr_c

# elementwise multiplication (Hadamard product)
arr_a_had_c = arr_a * arr_c

# matrix multiplication (inner product)
arr_a_inn_b = arr_a @ arr_b
# or equivalently
arr_a_dot_b = np.dot(arr_a, arr_b)

## Shape manipulation

# flatten to 1D array, ordered columnwise
arr_a_flat = arr_a.flatten()

# transpose
arr_a_trnsp = arr_a.T

# arbitrary reshape
arr_b_rshp = arr_b.reshape((2, 6))

# concatenation
# a 4x4 array
arr_a_v_c = np.vstack([arr_a, arr_c])
# a 2x8 matrix
arr_a_h_c = np.hstack([arr_a, arr_c])
```

### Linear Algebra

Provided via `numpy.linalg`. Similar functionality in `scipy.linalg`.

```python
import numpy as np

A = np.array([
    [1, 2, 3, 4],
    [-5, -6, 7, 8],
    [0, -1, 4, 3],
    [9, 9, 9, 0],
])

# create a 4x1 array, -1 in the reshape is 'auto'
b = np.array([3, 0, 1, 4]).reshape((-1, 1))

# Norms
b_norm_2 = np.linalg.norm(b)
b_norm_1 = np.linalg.norm(b, ord=1)

# Eigendecomposition
# W is a 1D array of eigenvalues
# V is the matrix of eigenvectors (columns)
W, V = np.eig(A)

# Linear solver
x = np.linalg.solve(A, b)
```

### ODEs

Provided in `scipy.integrate`. Scipy is annoying in that its base namespace isn't populated by the submodules, so you have explicitly import each submodule.

```python
from scipy import integrate
from matplotlib import pyplot as plt

def ode_model(t, y, mass, gravity, friction):
    """A model of projectile motion"""
    x, y, u, v = y[:4]
    speed = np.sqrt(u**2 + v**2)
    x_friction = friction * (u/speed)
    y_friction = friction * (v/speed)
    return [
        u, 
        v,
        -x_friction*u,
        -gravity/mass - y_friction*v,
    ]

# solve options
t_span = [0, 6]   # time span of integration
init_conditions = [0, 0, 40, 10]    # initial conditions (x, y, u, v)
parameters = {
    'mass': 3,
    'gravity': 9.81,
    'friction': 0.2,
}
# transform parameters to something that the IVP solver can use
parameter_values = list(parameters.values())

# define an event that stops the integration when we hit y=0
def hits_ground(t, y, *args):
    return y[1]

hits_ground.terminal = True
hits_ground.direction = -1

solution = integrate.solve_ivp(ode_model, t_span, init_conditions,
                               args=parameter_values,
                               events=hits_ground,
                               dense_output=True)   # this option provides an interpolator 

# smooth out the solution using the interpolator
t_smooth = np.linspace(np.min(solution.t), np.max(solution.t), 2001)
y_smooth = solution.sol(t_smooth).T

plt.figure()
plt.plot(y_smooth[:,0], y_smooth[:,1])
plt.xlabel('x')
plt.ylabel('y')
```
![Plot of the horizontal distance (x) vs vertical distance (y)](/images/blog/whiplash_py/xy.png)
