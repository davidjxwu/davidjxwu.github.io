---
title: Animations with Beamer
date: "2023-08-15"
tags: ["latex", "software"]
---

I've always struggled getting animations working with beamer. The libraries can be fragile, and because I'm usually on a Linux machine that's a stable release or two behind for work, and have no real invested interest in learning how to make things work, it's hard to get (valid) pdf outputs from beamer to render in the available pdf readers.

Of course, this works fine with standard xelatex using the animate library and rendered by Adobe PDF Reader (e.g. on Windows). But I'm not in that position.

I came across [an intriguing tex stackexchange thread](https://tex.stackexchange.com/questions/235139/using-the-animate-package-without-adobe) while searching for answers. In this thread, user [AlexG](https://tex.stackexchange.com/users/1053/alexg) details how to use latex to emit dvi files that can be converted with `dvisvgm` to svg files that can be rendered by a browser. modern browsers have native javascript support, which is the thing that is required to rendering animations produced by the animate library.

Sadly, the answer runs into a small problem with xelatex, which is required, for example, to use the fontspec library to utilise system fonts. Fortunately, there's onyl a few small tweaks to make it work.

Firstly, remove the hypertex option from the documentclass command to allow xelatex to work

```latex
\documentclass[dvisvgm, aspectratio=169]{beamer}
...
```

Then the compilation steps become:

```bash
xelatex --no-pdf svgbeamer
xelatex --no-pdf svgbeamer
dvisvgm --zoom=-1 --font-format=woff2 --bbox=papersize --page=1- --linkmark=none svgbeamer.xdv
```
noting that xelatex seems to emit .xdv files, which dvisvgm won't pick up by default, so you have to explicitly point to it.

And you now have your svg files, ready to present from any modern browser.