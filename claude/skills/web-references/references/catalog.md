# Catalog

"What it is" quotes or condenses each site's own description, read on the date shown. "Use for" is what it proved
useful for in practice, or what it is meant for. Re-read a licence before vendoring; these move.

## Look and component libraries

| Site | What it is | Use for | Licence / trap |
|---|---|---|---|
| [uiarc.dev](https://uiarc.dev/components/) · repo [kuratlielia/arc-library](https://github.com/kuratlielia/arc-library) | Arc UI: "free, open source React components with calm motion". 112 components + 22 blocks (read 2026-10-16); React 19, CSS modules over tokens in `registry/foundation.css`, Motion (motion.dev), some Radix and lucide-react; installs from the shadcn registry `@uiarc` | The base look: neutral oklch grays (dark ground oklch 19%), radii 18/26/34 px and pills, one lavender-to-peach gradient, Geist display + Inter body, ease `(.16,1,.3,1)` plus a `linear()` spring, 120 to 580 ms. Component behaviour contracts (accordion, tabs with sliding indicator, sheet, hold-to-confirm, marquee, number ticker...) | MIT, (c) 2026 Elia Kuratli: keep the notice in ported files. Arc Pro items are not in the repo. No usable Svelte port (2026-10-16): `michaelcosj/arc-library-svelte` is an untouched fork, `anylyralabs/uiarc-vue` is Vue with no licence. Arc's `timeline` is an activity feed grouped by day, not a process timeline |
| [reactbits.dev](https://reactbits.dev) · repo [DavidHDev/react-bits](https://github.com/DavidHDev/react-bits) | "The largest open-source library of animated, interactive, and customizable react & next.js components": 217 components (Animations 38, Backgrounds 64, Components 48, Micro 34, TextAnimations 33; counted 2026-10-15). Source under `src/ts-default/<Category>/<Name>/` | Worth porting to Svelte: LaserFlow (a hero beam), Grainient (silky gradient field), TextType, LogoLoop, TearTicket, SplitFlapText, Counter, GradualBlur, SpotlightCard, ScrollStack, swipe and hold micro-interactions | **MIT + Commons Clause.** Allowed: use, modify and port inside an app, site or product, commercially too, keeping the copyright notice. Forbidden: selling or redistributing "the components themselves, whether alone, in a bundle, or as a ported version": never publish the ports as a package, repo or standalone gallery (a public demo route counts). Put ports in one folder with a `NOTICE`; each file names its source component. Replace their deps (motion/react, gsap, @hugeicons) with plain code. WebGL ones cannot be verified in a headless browser without WebGL; prefer canvas, SVG or CSS ones |

## Motion

| Site | What it is | Use for | Licence / trap |
|---|---|---|---|
| [vibrant.design](https://vibrant.design/) | "Curated website, section, launch-video and ui design inspiration": videos per section type (hero, features, bento, pricing, cta, faq, footer) | The most useful gallery for motion (2026-10-15). Dark-hero kinds of motion seen there: liquid gradient (Arcade), rising light (Giga), hairline network (ToDesktop), halftone morph (Modal) | Study cards with an ffmpeg frame sheet (study-methods.md) |
| [motionin.design](https://motionin.design) | "Premium interactive web sections": physics-based, cursor-responsive sections sold as AI prompts | Kinds of section motion | Take the kind of motion, never the shipped prompt: its output is the generic "AI motion" look |
| [LottieFiles motion-design-skill](https://github.com/LottieFiles/motion-design-skill) | A Markdown-only motion skill, MIT | Its "corporate" profile: 200 to 400 ms, `cubic-bezier(0.2,0,0,1)`, micro-feedback 80 to 120 ms, exits about 70% of the entry, reduced motion = opacity only at half duration, no loops | Drop its "always three motion layers including ambient" rule |
| [Lenis](https://github.com/darkroomengineering/lenis) | Smooth scroll library, MIT | `lerp` 0.1, fine pointer only, only while motion is on; destroy it on pause (its `stop()` also locks the page) | |
| Rejected | | | GSAP: free but non-OSI, and Webflow can revoke the licence. three.js: about 545 KB. Astro when the stack is already settled |

## Layout, bands and backgrounds

| Site | Use for |
|---|---|
| [clerk.com](https://clerk.com) | Hairline frame and grid, chamfered "shoulders" at light/dark switches, bento cards one tone above the ground, the product behind the hero |
| [modal.com](https://modal.com) | Stepped dark grounds, full-width 1 px hairlines at 5 to 7% white, a bordered live panel in each block, one glyph-halftone motif repeated at large scale |
| [todesktop.com](https://todesktop.com) | One deep gradient band, circuit hairlines, an app window that grows on scroll, vignette cards |

How the three keep the ground from looking empty: [backgrounds.md](backgrounds.md).

## Hero, link cards and interactions

| Site | Use for | Trap |
|---|---|---|
| [openbot.run](https://openbot.run) | A clean og / link-preview card style: one line on a dark grid ("Meet [icon tile] name"). Its hero beam, matched by pixel measurement at the same zoom (violet `#7c3aed`, intensity 2, spill 0.15, speed 2.4, maxScale 2). Its agent-network interaction (zoom in on three agents, then pull back) | Its repo is **PolyForm Noncommercial**: never ship its code. The beam is React Bits LaserFlow (openbot commit cdfb650, "Bring back the React Bits beam"), so port that one instead. Record the interaction before rebuilding it |

## Inspiration galleries

| Site | What it is (its own words, 2026-10-15) | Use for |
|---|---|---|
| [dark.design](https://dark.design) | "The best hand-picked dark themed websites" | Dark themes |
| [a1.gallery](https://a1.gallery) | "A collection of the best websites found on the internet", updated nearly every day | Landing patterns |
| [minimal.gallery](https://minimal.gallery) | "Hand-picked web design inspiration", plus Framer and Webflow templates | Layout, type, spacing |
| [loadmo.re](https://loadmo.re) | "A curated archive of distinctive mobile websites and unconventional digital experiences" (Kim Boutin) | Mobile motion and layouts |
| [umanmade.com](https://umanmade.com) | "Curated directory of digital work made by humans, for humans" | Craft references |
| [landdding.com](https://landdding.com) | "Daily new web designs" with community upvotes | Landing visuals |
| [wonderlist.design](https://wonderlist.design) | 127 premium website templates in Figma (SaaS, agency, portfolio) | Section layouts |
| [wedoflow.com](https://wedoflow.com) | "210+ premium and unique Webflow templates" | Section layouts |
| [modulify.ai/templates](https://modulify.ai/templates) | Website templates built with the Modulify builder | Layouts only, not the builder |
| [searchsystem.co](https://searchsystem.co) | Not readable by scripts (a browser check blocks fetches) | Open it in a real browser |
| [mnmm.xyz](https://mnmm.xyz) | Exposes no title or description | Open it in a real browser |

## Logos, icons and brand marks

| Source | What it is | Use for | Licence / trap |
|---|---|---|---|
| [logoinspo.com](https://logoinspo.com) | "1,200+ hand-picked real and fictional logos" by style, industry and colour | Refining your own mark | Inspiration only |
| [logggos.club](https://logggos.club) | "A catalog of well-designed logos" by industry, theme, type and colour | Refining your own mark | Inspiration only |
| [iconly.design](https://iconly.design) | "2,400+ app, game, and web app icons" | App icon and favicon ideas | Inspiration only |
| [fontinlogo.com](https://fontinlogo.com) | "Find out what font is used in famous brand logos" | Choosing a wordmark typeface | |
| [ikonik.modulify.ai](https://ikonik.modulify.ai) | "50k+ open-source icons from over 45 projects", with an SVG editor | Icons | Each set has its own licence: check and record it per file |
| [logotouse.com](https://logotouse.com) | "Premium logos, ready to use in mockups" | Mockups only | Never as your own brand; check the licence |
| [Simple Icons](https://github.com/simple-icons/simple-icons) | Brand SVG icons | Tech and tool marks in diagrams | CC0-1.0; marks stay trademarks of their owners (nominative use only) |
| [Devicon](https://github.com/devicons/devicon) | Programming language and tool icons | Tech marks | MIT: keep the attribution |
| [WhatsApp brand resources](https://www.meta.com/brand/resources/whatsapp/whatsapp-brand/) | Meta's official logo pack (accept the guidelines to download) | A "works with WhatsApp" strip | Official files only, colours unmodified, not combined with another logo, not the most prominent element, no implied partnership |
| [SINPE Móvil brand manual](https://www.bccr.fi.cr/content/dam/bccr/sistema-de-pagos/informacion-general/manual-marca-sinpe-movil.pdf) | BCCR's manual (27 Feb 2026) | Showing SINPE Móvil as a payment method | Businesses may use it to promote the payment method if the manual's design is kept: grayscale and inverted versions only, no other colours or gradients, minimum 1 cm x 0.7 cm; PNG recommended for the web |
| Airbnb, Booking.com | | | Logos need written permission ([Airbnb](https://www.airbnb.com/help/article/3233), [Booking Holdings](https://www.bookingholdings.com/?p=11957)): write the names in text only |

Pattern that holds up: one file per theme as the brand ships it (white on dark, black or gray on light), never
recoloured, filtered or dimmed, and a `NOTICE` with each file's source, licence and fetch date. For a brand with no
guidelines, take the wordmark from its own site header, paths unchanged, and only as an explicit decision.

## Photos and images

| Source | Use for | Licence / trap |
|---|---|---|
| [Pexels](https://www.pexels.com) | Illustrative photos (places, rooms, no people) | Free licence, but it forbids implying endorsement: no stock faces presented as real customers or testimonials. Label illustrative photos as such |
| [Unsplash](https://unsplash.com) | Single hero or plate photos | Unsplash License. It blocks `curl`: download by hand and keep the master out of the repo; record the photographer in a `NOTICE` |
| NOIRLab, Pixabay | Astronomy and general photos | NOIRLab CC BY 4.0 needs a credit caption |
| [imageory.in](https://imageory.in) | Not usable | States no licence, terms or AI label anywhere a visitor can reach |
| AI images | Own-prompt images | Of the generators checked, only Adobe Firefly's and Stability's terms were verified for that use |

## Fonts

Self-hosted from `@fontsource-variable` packages, all SIL OFL 1.1: Geist (display), Inter (body), JetBrains Mono
(data), Plus Jakarta Sans. With a CSP of `font-src 'self'`, keep `.woff2` as files: a bundler that inlines a small
subset as a `data:` URI gets it blocked.

## Video and social clips

| Tool | Use for | Trap |
|---|---|---|
| [paperanimation.ai](https://paperanimation.ai) | Paper-style animations from an image, for social clips | Not for the site itself |
| HyperFrames CLI | A demo video from plain HTML (Apache-2.0) | Pin the version, turn telemetry off, never load its skills: they self-update from `@latest` and post reports to a public channel |
| Remotion | Video from React | React only; free up to 3 employees |
