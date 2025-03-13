---
title: "A note on interactive matplotlib plotting in Jupyterlab"
date: 2024-08-06
categories: 
    - python
---

I do a decent amount of exploratory analysis with Python. For this, I jump around different interactive tools. Initially it was just a REPL, but as I wanted to better persist the analysis between sessions, or work on the same session in different (physical) locations, it evolved into using Jupyter notebook solutions, which then became using JupyterLab (with ipympl for interactive plotting)

One issue I have with notebooks and JupyterLab is that their interactive plotting is a bit more involved than in a REPL-like environment.
Because the cells persist output, the figures are never closed, and there is no obvious way to do so when you rerun a cell.
Additionally, the creation of a figure requires the invocation of `plt.figure()` or equivalent, which creates a while new figure by default. If we are to constantly tweak our figures, this can lead to an excess number of deprecated figures that nonetheless still take up memory. 

I have found a neat solution to this, and that is by _naming_ the figure objects. `plt.figure` supports a `str`-type identifier as the first positional argument. By doing this, we can specify the figure and modify our code in the following way:

```python
%matplotlib widget

fig = plt.figure('example_figure')
fig.clf()

# plotting code here

fig.show()
```

This allows us to tweak some analysis code and regenerate a figure, but not allocate a new chunk of memory to it.
The `Figure.clf` is required to clear the figure, as to not plot on top of previous plots; of course this could be removed to exploit that behaviour.
I have also found that the `Figure.show` is needed to surface the interactive object - simply using the representation feature on the figure:

```python
%matplotlib widget

fig = plt.figure('example_figure')

# plotting code here

fig # -> produces static plot
```

surfaces a static version instead.

