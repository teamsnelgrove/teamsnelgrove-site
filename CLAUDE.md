# teamsnelgrove.com

My personal blog, CV, and how people can connect with me.

## Tools

- **Zine**: HTML content is generated with the Zine static site generator.

## HTML guidelines

Use semantic elements where possible even at the expense of visual styling. Never use `<div>` or `<span>` when a semantic element exists.

## CSS guidelines

### Location and dependencies

- All CSS lives in a single file: `assets/style.css`. Do not create additional stylesheets, do not inline `<style>` blocks in templates, and do not use `style=""` attributes except for one-off content-specific cases that cannot be expressed semantically.
- No external CSS dependencies. No `@import` of remote stylesheets, no CDN links, no font services (use system font stacks or self-hosted fonts in `assets/`).
- No build process. The CSS shipped is the CSS authored. No PostCSS, Sass, Tailwind, or preprocessing of any kind.

### Browser target

- Evergreen browsers only (latest Chrome, Firefox, Safari, Edge). Do not add vendor prefixes, polyfills, or fallbacks for legacy browsers.
- Use modern CSS freely: native CSS nesting, `:where()` / `:is()`, logical properties (`margin-block`, `padding-inline`), container queries (`@container`), `clamp()` / `min()` / `max()`, custom properties, `:has()`, `text-wrap: balance` / `pretty`, `aspect-ratio`.

### Reset

- Use a full modern reset at the top of the file (Josh Comeau style). Required rules:
  - `*, *::before, *::after { box-sizing: border-box; }`
  - Remove default margins on body, headings, paragraphs, lists, figures, blockquotes.
  - `body { line-height: 1.5; -webkit-font-smoothing: antialiased; }`
  - `img, picture, video, canvas, svg { display: block; max-width: 100%; }`
  - `input, button, textarea, select { font: inherit; }`
  - `p, h1, h2, h3, h4, h5, h6 { overflow-wrap: break-word; }`
  - `h1, h2, h3, h4, h5, h6 { text-wrap: balance; }`
  - `p { text-wrap: pretty; }`

### Layout

- Use Flexbox and CSS Grid only. Do not use floats or absolute positioning for layout (absolute positioning is fine for genuinely overlaid elements like badges or tooltips).
- Single centered column for primary content. Constrain reading width with `max-width` on a semantic wrapper (e.g. `main`, `article`).

### Responsive strategy

- Mobile-first. Base styles assume a narrow viewport with a single stacked column. Enhance upward.
- Prefer intrinsic sizing over media queries: `clamp()` for fluid type and spacing, `max-width` with `min()` for containers, `grid-template-columns: repeat(auto-fit, minmax(...))` for grids.
- Use container queries (`@container`) over viewport media queries when sizing depends on the parent component, not the page.
- Add a viewport breakpoint only when intrinsic sizing cannot express the change.

### Design tokens

- Define design tokens as custom properties on `:root`. Tokens cover at minimum:
  - Color: `--color-bg`, `--color-text`, `--color-link`, `--color-muted`, `--color-rule`.
  - Spacing scale: `--space-1` through `--space-6` (or similar), fluid via `clamp()`.
  - Type scale: `--text-sm`, `--text-base`, `--text-lg`, `--text-xl`, fluid via `clamp()`.
  - Font stacks: `--font-serif`, `--font-mono`.
  - Layout: `--measure` (max reading width), `--radius`.
- Reference tokens in component rules. Do not hardcode colors or spacing values outside `:root`.
- No dark mode. Do not add `prefers-color-scheme` rules.
- No print styles. Do not add `@media print`.

### Typography

- Serif body text. Default stack: `Georgia, "Times New Roman", serif` (assigned to `--font-serif`).
- Fluid type scale via `clamp()`. Example: `--text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);`
- Line height: 1.5 for body, tighter (1.1–1.3) for headings.

### Selectors

- Prefer class selectors for components. Element selectors are appropriate for base typography and reset rules.
- Be pragmatic: a class is not required when an element selector inside a scoped parent reads more clearly.
- Use native CSS nesting for component-local rules. Keep nesting shallow (max 2 levels).
- Use `:where()` to keep specificity low on base rules so component classes can override without `!important`.
- Do not use ID selectors for styling.
- Do not use `!important` except as a last-resort comment-justified override.

### File order

Top-to-bottom in `style.css`:

1. Reset
2. `:root` design tokens
3. Base element styles (`body`, `h1`–`h6`, `p`, `a`, `ul`, `ol`, `blockquote`, `code`, `pre`, `hr`, `img`, `figure`)
4. Layout primitives (`main`, `article`, `header`, `footer`, `nav`)
5. Components (post listing, devlog entry, RSS link, etc.)
6. Utilities (only if needed)

Be pragmatic for components: keep a component's rules together (including its container queries and modifier states) rather than scattering them across the file.

### Syntax highlighting

- Zine highlights fenced code blocks via [flow-syntax](https://github.com/neurocyte/flow-syntax), a tree-sitter wrapper. The language tag on the fence becomes a class on `<code>` (e.g. ```` ```ziggy ```` → `<code class="ziggy">`), and each token gets a class derived from its tree-sitter capture name with dots converted to underscores (e.g. `punctuation.bracket` → `.punctuation_bracket`).
- Capture names are a shared vocabulary across grammars (`keyword`, `string`, `comment`, `function`, `punctuation`, `constant`, `field`, `error`, etc.), so a single capture-name → color mapping covers every language. Style by capture, not by language.
- Theme: Catppuccin Latte. Palette is exposed as `--ctp-*` custom properties on `:root` in `style.css`. The mapping from helix capture names to Latte colors mirrors [catppuccin/helix's `catppuccin_latte.toml`](https://github.com/catppuccin/helix/blob/main/themes/default/catppuccin_latte.toml).
- Tokens may carry multiple classes (e.g. `class="error punctuation_bracket"` for a bracket inside a parse error). Order rules so the more specific intent wins — in this codebase, `.error` is declared last in the `pre code` block so it overrides the underlying capture color.

### Aesthetic target

Minimal, clean, content-first. Inspired by andrewconner.com:

- Neutral background, near-black text, restrained palette.
- Serif body type, generous whitespace, single centered column.
- Unobtrusive links (underline on hover or subtle color).
- Clear heading hierarchy without heavy visual weight.
- Section dividers should be quiet (`<hr>` styled minimally, or whitespace alone).

When in doubt, remove rather than add.

## Project structure

```
teamsnelgrove-site/
  zine.ziggy              # Site configuration
  content/                # SuperMD content (.smd files)
    index.smd             # Homepage (section root)
    about.smd             # Standalone page
    blog/
      index.smd           # Blog section root (lists subpages)
      first-post/
        index.smd         # Post with page assets
        fanzine.jpg       # Page asset (belongs to first-post)
      second-post.smd     # Single-file post (no page assets)
    devlog/
      index.smd           # Devlog archive section root
      1990.smd            # Devlog year page (microblog entries)
      1989.smd            # Older devlog year
  layouts/                # SuperHTML templates (.shtml files)
    index.shtml           # Homepage layout
    page.shtml            # Generic page layout
    post.shtml            # Blog post layout (with prev/next nav)
    blog.shtml            # Blog listing layout
    blog.xml              # Blog RSS feed layout
    devlog.shtml          # Devlog feed layout
    devlog.xml            # Devlog RSS feed layout
    devlog-archive.shtml  # Devlog archive listing
    templates/
      base.shtml          # Base template (inherited by all layouts)
  assets/                 # Site-wide assets; css, js, fonts
    style.css
```
