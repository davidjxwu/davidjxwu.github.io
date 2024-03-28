---
title: "A Small Terminal Annoyance"
date: '2024-03-28'
tags: ['software']
---

When teaching this week, I confused a student because my terminal emitted the `^C` characters when I hit `Ctrl+C` to cancel something in my terminal. This caused some grief as they stuck this to the end of their terminal command which made the argument invalid.

So, I decided to work out ways to remove this. ChatGPT showed me `trap`, which intercepts particular signals and does something before they are passed on, but it didn't resolve the issue of the `^C` characters being printed. A good ole' Google search later showed me that this was a problem someone else had encountered and solved: [here](https://linux.m2osw.com/remove-ctrl-C-from-being-printed-in-console). They give the actual answer which is to manage the TTY settings. A simple fix is to use:

```
stty -ctlecho
```

which turns off the printing of the character. This is a transient action, so I've added to my Bash.

Because my PS1 starts with a clock, I've also used `trap` to give me a (different) visual indicator in the form of a red, crossed-out clock on the line that was cancelled.

The two new lines in my `~/.bashrc`:

```
stty -ctlecho
trap 'echo -n -e "\e[38;5;196;48;5;8;9m $(date +%T) \e[0m"' SIGINT
```