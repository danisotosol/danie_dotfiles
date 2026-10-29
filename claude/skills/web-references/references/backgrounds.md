# Keeping a page from looking empty

Question behind it: why does a long dark page look empty, and what do the references do about it? Clerk, Modal and
ToDesktop were captured top to bottom at 1440x900 and their DOM measured on 2026-10-15. The numbers can change
when the sites change.

## Finding

None of them fills the ground. Plain, flat ground is about half of each page (Clerk 52%, Modal 44.5% of 30 px
tiles, ToDesktop 52 to 70% of each viewport in its white part). What differs is how the empty space is organised.
The ground never moves; motion lives only inside objects (Modal: 0% frame-to-frame change on the ground).

## Five devices

1. **Tonal bands with hard switches.** Clerk alternates white, near-black `#131316` and gray-50 (dark bands are 39%
   of the page). Modal steps through 3 or 4 dark grounds plus one light sage band mid-page. ToDesktop runs one
   2850 px gradient band, then white. A long page never shows one continuous field of the same black.
2. **Drawn seams.** Clerk draws 45-degree chamfered "shoulders" (two small SVG corners and a bar on the column
   width) at every light/dark switch and repeats the motif in small UI. Modal draws full-width 1 px hairlines at 5
   to 7% white.
3. **Frames that enclose the emptiness.** Hairline grids with collapsed 1 px borders; bento cards one tone lighter
   than the ground with 8 px gutters (Clerk); a bordered panel with a live diagram in the right half of nearly
   every block (Modal). Empty space inside a frame reads as a cell, not a hole. Lines run a little past the objects
   (Clerk: dotted lines about 80 px beyond a grid); none of the three draws page-long rails.
4. **One large object per 900 px viewport**, often the same motif repeated (Modal's glyph halftone appears four
   times at large scale; Clerk puts a live product card over a faded mosaic of 60 real component shots behind
   the hero).
5. **Static, anchored light, used sparingly.** One big soft glow image with a blend overlay (Clerk), radial glows at
   the bottom of the hero and footer (Modal), a light PNG over a gradient (ToDesktop). Never an animated light
   layer.

## Order of fixes for a page that feels empty

Bands, then seams, then frames, then one object per viewport, then motion only inside objects. Keep each theme in
its own tones: avoid a light band inverted inside the dark theme, even though Clerk and Modal do it.
