---
title: "Python on Windows: pyenv-win"
date: "2025-01-29"
tags: ["python", "rant"]
---

Man I hate using Python on Windows.

For the longest time, I was using miniconda to manage my environment(s) on Windows. It was an easy, plug-and-play system, which was broadly supported.
However, I had 2 problems:
  - Somehow, IPython broke in the VS Code terminal for me. The IPython REPL would always freeze after typing import. No idea why, it works in a standalone terminal.
  - Recently, I upgraded my Powershell from 7.4.something to 7.5.0, and something changed in how the conda script was activated, which caused the conda command to break in Powershell for me.

So I uninstalled it.

I had been thinking about uv for a while, but I really need a "global" environment, since I'm installing relatively large packages, like scipy, and I fragment my work into multiple projects, which makes redundant copies of libraries a particularly sore point for me.
I know there is a caching system, and various workarounds, but they seem like a lot of effort for something that I'm not 1000% invested in (a lock file for dependencies).

One thing I had seen at some point in the past was pyenv-win, a port of pyenv for Windows. I already use a pyenv + virtualenvwrapper setup on my non-Windows machine, so this was particularly appealing.
Luckily, there is also a port of pyenv-venv (in the form of pyenv-win-venv) for Windows, which allows management of venvs in a "global" location.

The installation was fast and pain-free, and full functionality only required a small change to the invocation script for pyenv-win-venv (that I'm going to PR soon).

I finally have a working environment manager on Windows, along with a working VS Code IPython terminal.
As a bonus, I don't have to deal with conda (at least until I have to do ML stuff...)