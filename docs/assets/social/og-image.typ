// Social preview card for this site, 1200x630.
//
// This is one way to produce a card, not a house style or a template to copy.
// It is committed so that this site's own card can be regenerated from source
// rather than being an orphaned binary; anything that emits a 1200x630 PNG
// would do just as well.
//
// Rendered to og-image.png from `docs/` with:
//
//   typst compile --root . --format png --ppi 72 \
//     assets/social/og-image.typ assets/social/og-image.png
//   magick assets/social/og-image.png -alpha off -strip \
//     -define png:compression-level=9 assets/social/og-image.png
//
// Typst writes an alpha channel that is opaque everywhere, since the page has
// a solid fill. Dropping it is lossless and takes the file from 40 KB to 39 KB.
//
// `--root .` is what lets the template reach the mark in assets/icons/; Typst
// otherwise sandboxes it to its own directory.
//
// The page is 1200pt by 630pt and the render is 72 ppi, so one point is one
// pixel and the output is exactly 1200x630.
//
// The mark comes in as icon-512.png rather than icon.svg because Typst renders
// SVG through resvg, which does not evaluate `prefers-color-scheme` and would
// draw the light variant: an ink outline, invisible on midnight. That PNG is
// already the dark variant on an opaque midnight square, so it sits seamlessly
// on the page fill.
//
// Colours and fonts come from ../../_brand.yml. Space Grotesk ships no static
// 600 face, so the title uses Bold, the closest heavier match for display type.

#let midnight = rgb("#0B1220")
#let mist = rgb("#DCE3EC")
#let mist-muted = rgb("#8EA0B8")

#set page(width: 1200pt, height: 630pt, margin: 80pt, fill: midnight)
#set text(fill: mist)

#align(horizon)[
  #stack(
    dir: ttb,
    spacing: 44pt,
    image("/assets/icons/icon-512.png", width: 128pt),
    text(font: "Space Grotesk", weight: 700, size: 92pt, tracking: -1.5pt)[
      Quarto Codespaces
    ],
    text(font: "IBM Plex Sans", weight: 300, size: 34pt, fill: mist-muted)[
      Quarto, R, Python, and Julia, ready to render.
    ],
  )
]
