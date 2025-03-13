---
title: I rebuilt my resume pipeline in pandoc
date: "2024-06-06"
categories: ['software', 'latex']
---

A few years ago, I stole a CV template from the now-absorbed ShareLaTeX platform in order to build a resume for finding graduate positions. This template was, of course, in LaTeX, and had some odd constructions. Being relatively new to the language, I made do; over the years, as I became marginally more familiar with LaTeX, I made some small additions, mainly for papers and conferences, and other nice academic-sounding things.

Then, last year, I got fed up. Being a new member in what amounts to a statistics department, I had been indoctrinated with markup engines like pandoc (which I had known about), knitR (vaguely familiar), and quarto (so new they haven't sorted out their documentation properly). _Why couldn't my CV be in plain text_, I wondered, as I tried to mangle another \WorkEntry into the resume.

And so, I began reformatting the damned latex document into a file that pandoc could digest. 
Initially, I had wanted to write an actual markdown document, where each section would be nicely automatically formatted into what my LaTeX template had looked like. Unfortunately, I could not do that -- it was beyond my realm of expertise. Instead, I decided to abuse the YAML header of a pandoc-flavoured markdown file in order to generate an entire LaTeX document.

The resume, along with the template can be found on Github: https://github.com/dwu402/resume
