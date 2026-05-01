---
name: zine-authoring
description: Zine is alpha static site generator with custom authoring languages not in Claude's training data. Use this document as the authoritative reference when authoring content, creating templates, or configuring the site
---

**Sections vs pages:** A section is defined by the presence of an `index.smd` file. Section pages list their subpages via `$page.subpages()`. Non-index `.smd` files are leaf pages. Pages within a section are ordered by their frontmatter `date` field.

**Page assets vs site assets:** Files next to a page's `.smd` file (or in its directory for `index.smd` pages) are page assets, accessed via `$page.asset()` or `$image.asset()`. Files in `assets/` are site assets, accessed via `$site.asset()` or `$image.siteAsset()`.

## zine.ziggy configuration

The site config file uses Ziggy syntax:

```ziggy
Site {
    .title = "Welcome to my site!",
    .host_url = "https://example.com",
    .content_dir_path = "content",
    .layouts_dir_path = "layouts",
    .assets_dir_path = "assets",
    .static_assets = [
        "font.woff2",
        "style.css",
        "script.js",
    ],
}
```

Fields: `.title` (site title), `.host_url` (canonical URL), `.content_dir_path`, `.layouts_dir_path`, `.assets_dir_path` (directory paths), `.static_assets` (array of asset filenames served as-is without hashing).

## SuperMD content authoring (.smd files)

### Frontmatter

Every `.smd` file starts with a Ziggy frontmatter block between `---` delimiters:

```
---
.title = "Page Title",
.date = @date("2024-01-15T00:00:00"),
.author = "Author Name",
.layout = "post.shtml",
.draft = false,
---
```

All frontmatter fields (Ziggy schema):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `?bytes` | no | Page title |
| `description` | `?bytes` | no | Short description accessible from section page |
| `author` | `?bytes` | no | Main author |
| `date` | `?@date` | no | RFC 3339 date, e.g. `@date("2024-10-24T00:00:00")` |
| `tags` | `?[bytes]` | no | Array of tag strings |
| `aliases` | `?[bytes]` | no | Alternative paths for this content |
| `draft` | `?bool` | no | When true, file is ignored during build |
| `layout` | `bytes` | **yes** | Path to layout file in layouts directory |
| `alternatives` | `?[Alternative]` | no | Alternative renderings (e.g. RSS feeds) |
| `skip_subdirs` | `?bool` | no | Ignore other .smd files in this directory (only for index.smd) |
| `custom` | `?map[any]` | no | User-defined properties accessible in templates |

Alternative struct fields: `.layout` (layout path), `.output` (output path), `.name` (name for referencing), `.title` (optional), `.type` (optional content-type).

### Markdown syntax

SuperMD extends Markdown (cmark-gfm) with Scripty expressions in link syntax. Standard markdown features work: headings, bold, italic, lists, tables, strikethrough, autolinks, code blocks, blockquotes.

**Fenced code blocks** with language identifiers get static syntax highlighting via Tree Sitter:

````
```zig
const x = 42;
```
````

### Directives

Directives use the link syntax `[]($directive.method())` or `[text]($directive.method())`. Method calls are order-independent (builder pattern). All directives support these universal methods:

- `fn id(str)` -- Sets HTML `id` attribute
- `fn attrs(str, [str...])` -- Sets HTML `class` attribute(s)
- `fn title(str)` -- Metadata title (not rendered directly)
- `fn data(str, str, [str...])` -- Adds `data-*` attributes

**Spaces in directives** require diamond brackets due to Markdown parsing:

```
Wrong:  []($link.page('foo').title('my page'))
Right:  [](<$link.page('foo').title('my page')>)
```

#### `$section` -- Content sections

Splits a page into independently renderable sections.

As a standalone directive:
```
[]($section.id('intro'))
## Introduction
Content here...
```

As a heading wrapper (sugar syntax):
```
## [Introduction]($section.id('intro'))
Content here...
```

The heading wrapper is sugar for:
```
[]($section.id('intro'))
## [Introduction]($link.ref('intro'))
Content here...
```

Sections do NOT nest. Content continues until the next `$section` or end of document. Heading levels are irrelevant to section boundaries.

Render a specific section in a template:
```html
<article :html="$page.contentSection('intro')"></article>
```

#### `$block` -- Styled containers

Turns a blockquote into a styled container. Automatically gets CSS class `block`. Can nest. Cannot be rendered independently.

Basic block:
```
>[]($block)
>This is a block.
```

Block with heading (creates title + body sub-containers):
```
># [NOTE]($block)
>This is a block note.
```

Block with attributes:
```
># [Warning]($block.attrs('warning'))
>Warning content here.
```

Collapsible block (`<details>`/`<summary>`):
```
># [Click to expand]($block.collapsible(false))
>Hidden content. Argument: true = open by default, false = closed.
```

- `fn collapsible(bool)` -- Render as `<details>` element. Bool sets default open state.

#### `$heading` -- Heading attributes

```
# [Title]($heading.id('foo').attrs('bar'))
```
Renders: `<h1 id="foo" class="bar">Title</h1>`

#### `$text` -- Inline text attributes

```
Hello [World]($text.attrs('highlight'))!
```
Renders: `Hello <span class="highlight">World</span>!`

#### `$link` -- Links

Source location methods:
- `fn url(str)` -- External URL
- `fn asset(str)` -- Page asset
- `fn siteAsset(str)` -- Site asset
- `fn buildAsset(str)` -- Build asset
- `fn site(?str)` -- Site home page (optional locale code)
- `fn page(str, ?str)` -- Page by path relative to content dir (exclude .smd suffix; auto-matches `foo.smd` or `foo/index.smd`)
- `fn sibling(str, ?str)` -- Page relative to current section
- `fn sub(str, ?str)` -- Page relative to current page (only works on index.smd pages)

Behavior methods:
- `fn new(bool)` -- Open in new tab/window
- `fn alternative(str)` -- Link to alternative version (e.g. RSS)
- `fn ref(str)` -- Deep-link to element id (build-time validated)
- `fn unsafeRef(str)` -- Deep-link without id validation (for template-defined ids)

Examples:
```
[About page]($link.page('about'))
[RSS feed]($link.page('blog').alternative('rss'))
[Section ref]($link.ref('intro'))
```

#### `$image` -- Images

Source methods: `fn url(str)`, `fn asset(str)`, `fn siteAsset(str)`, `fn buildAsset(str)` (same as link).

Image-specific methods:
- `fn alt(str)` -- Alt text for accessibility
- `fn linked(bool)` -- Wrap image in link to itself
- `fn size(int, int)` -- Set dimensions. `size(800, 0)` = width 800, maintain aspect ratio. `size(0, 600)` = height 600, maintain aspect ratio.

Text in `[]` becomes the caption:
```
[Photo of a cat]($image.asset('cat.jpg').alt('A tabby cat sleeping'))
```

#### `$video` -- Videos

Source methods: same as image (`url`, `asset`, `siteAsset`, `buildAsset`).

Video-specific methods:
- `fn loop(bool)` -- Loop playback
- `fn muted(bool)` -- Start muted
- `fn autoplay(bool)` -- Auto-play
- `fn controls(bool)` -- Show playback controls
- `fn pip(bool)` -- Allow Picture-in-Picture (false to disable)

```
[]($video.asset('demo.mp4').controls(true).loop(true))
```

#### `$code` -- Embedded code from files

Text in `[]` becomes caption. Methods:
- `fn asset(str)` / `fn siteAsset(str)` / `fn buildAsset(str)` -- Source location
- `fn language(str)` -- Language for syntax highlighting
- `fn lines(int, int)` -- Include only specified line range (second arg is inclusive)

```
[Main function]($code.asset("main.zig").lines(10, 15).language("zig"))
```

#### `$mathtex` -- LaTeX math

Inline math (formula must be in backticks):
```
The formula [`x^2 + y^2 = r^2`]($mathtex) describes a circle.
```

Block math:
````
```=mathtex
\begin{aligned}
f(t) &= \int_{-\infty}^\infty F(\omega) \mathrm{d}\omega
\end{aligned}
```
````

Requires JS/CSS dependencies (Temml, KaTeX, or MathJax) wired into the base template.

### Vanilla markdown mappings

Standard markdown link/image syntax is resolved to directives:

**Links:**
| Syntax | Resolves to |
|--------|------------|
| `[text](https://example.com)` | `$link.url('https://example.com').new(true)` |
| `[text](#anchor)` | `$link.ref('anchor')` |
| `[text](/docs/)` | `$link.page('docs')` |
| `[text](./child)` | `$link.sub('child')` |
| `[text](sibling)` | `$link.sibling('sibling')` |

**Images:**
| Syntax | Resolves to |
|--------|------------|
| `![](https://example.com/pic.jpg)` | `$image.url(...)` |
| `![](/logo.jpg)` | `$image.siteAsset('logo.jpg')` |
| `![](cat.jpg)` | `$image.asset('cat.jpg')` |
| `![Caption](cat.jpg "alt text")` | `$image.asset('cat.jpg').alt('alt text')` with caption |

Note: SuperMD breaks Markdown compatibility -- text in `![]` becomes caption (not alt), and the title string becomes alt (not title).

### Inline HTML escape hatch

SuperMD forbids inline HTML. To embed raw HTML, use an `=html` code block:

````
```=html
<script>alert("inlined")</script>
```
````

Zine validates the HTML before inlining.

## SuperHTML templates (.shtml files)

### Scripting attributes

Any HTML attribute can contain a Scripty expression (prefixed with `$`):

```html
<a href="$site.page('about').link()">About</a>
<h1 class="$page.title.len().gt(25).then('long')">...</h1>
```

### Logic attributes

**`:text`** -- Sets element content to HTML-escaped Scripty result. Must evaluate to String or Int. Element body must be empty.
```html
<h1 :text="$page.title"></h1>
```

**`:html`** -- Same as `:text` but does NOT escape HTML. Use for rendered content.
```html
<article :html="$page.content()"></article>
```

**`:if`** -- Conditionally renders element body. Accepts Bool or `?any` (optional). When the optional value is present, it becomes available as `$if`.
```html
<nav :if="$page.nextPage?()">
    Next: <a href="$if.link()" :text="$if.title"></a>
</nav>
```

**`:loop`** -- Repeats element body for each item. Expression must evaluate to `[any]`. Iterator available as `$loop`. Use `$loop.up()` for outer loop in nested loops.
```html
<ul :loop="$page.subpages()">
    <li>
        <a href="$loop.it.link()" :text="$loop.it.title"></a>
    </li>
</ul>
```

### Custom elements

**`<ctx>`** -- Renders no tags in output. Supports all logic attributes. Attributes become fields of `$ctx`. No shadowing allowed.
```html
<ctx about="$site.page('about')">
    <a href="$ctx.about.link()" :text="$ctx.about.title"></a>
</ctx>
```

**`<extend>`** -- Declares template inheritance. Must be first element.
```html
<extend template="base.shtml">
```

**`<super>`** -- Defines extension points in base templates. Parent element must have an `id`.

### Template inheritance

Base template defines extension points with `<super>`:

```html
<!-- layouts/templates/base.shtml -->
<!DOCTYPE html>
<html>
    <head id="head">
        <meta charset="utf-8">
        <title :text="$site.title"></title>
        <super>
    </head>
    <body id="body">
        <super>
    </body>
</html>
```

Child layout extends and fills extension points by matching parent tag + id:

```html
<!-- layouts/page.shtml -->
<extend template="base.shtml">
<head id="head">
</head>
<body id="body">
    <h1 :text="$page.title"></h1>
    <article :html="$page.content()"></article>
</body>
```

The child's `<body id="body">` replaces the `<super>` inside the base template's `<body id="body">`. Tag and id must both match -- mismatches produce compile errors. Extension chains can be multiple levels deep, with intermediate templates both fulfilling and defining `<super>` points.

## Scripty API reference

Scripty is a small expression language embedded in strings. All variables start with `$`. Supports dot navigation and function calls. Literals: strings (`'single'` or `"double"`), integers, floats, booleans (`true`/`false`). Trailing commas allowed in function calls.

### Global variables (SuperHTML templates)

| Variable | Type | Description |
|----------|------|-------------|
| `$site` | Site | Site configuration and page access |
| `$page` | Page | Current page being rendered |
| `$build` | Build | Build-time data (timestamp, git info) |
| `$loop` | Iterator | Current loop iteration (inside `:loop`) |
| `$if` | any | Unwrapped optional value (inside `:if` with `?any`) |
| `$ctx` | Ctx | Attributes from enclosing `<ctx>` elements |

### Global variables (SuperMD content)

`$section`, `$block`, `$heading`, `$text`, `$mathtex`, `$link`, `$code`, `$image`, `$video` -- the 9 directives described above.

### Site

| Member | Type | Description |
|--------|------|-------------|
| `.title` | String | Site title |
| `.host_url` | String | Canonical host URL |
| `fn link()` | String | Link to site root |
| `fn page(str)` | Page | Get page by content path |
| `fn pages(str, ...)` | [Page] | Get multiple pages (or all if no args) |
| `fn asset(str)` | Asset | Get site asset by filename |
| `fn localeCode()` | String | Current locale code |
| `fn localeName()` | String | Current locale name |
| `fn locale(str)` | Site | Get site in different locale |

### Page

| Member | Type | Description |
|--------|------|-------------|
| `.title` | String | Page title |
| `.description` | String | Page description |
| `.author` | String | Page author |
| `.date` | Date | Page date |
| `.tags` | [String] | Page tags |
| `.draft` | Bool | Draft status |
| `.layout` | String | Layout template path |
| `.aliases` | [String] | Alternative paths for this page |
| `.alternatives` | [Alternative] | Alternative versions (e.g. RSS) |
| `.skip_subdirs` | Bool | Skip subdir content (index.smd only) |
| `.custom` | Map | Custom frontmatter fields |
| `fn link()` | String | URL path to this page |
| `fn permalink()` | String | Full permalink |
| `fn content()` | String | Rendered HTML content |
| `fn contentSection(str)` | String | Rendered HTML of a named section |
| `fn hasContentSection(str)` | Bool | Whether section exists |
| `fn contentSections()` | [ContentSection] | All content sections |
| `fn subpages()` | [Page] | Child pages (for section pages) |
| `fn subpagesAlphabetic()` | [Page] | Child pages sorted alphabetically |
| `fn nextPage?()` | ?Page | Next sibling page (by date) |
| `fn prevPage?()` | ?Page | Previous sibling page (by date) |
| `fn hasNext()` | Bool | Whether a next page exists |
| `fn hasPrev()` | Bool | Whether a previous page exists |
| `fn linkRef(str)` | String | URL with fragment id (build-time validated) |
| `fn parentSection()` | Page | Parent section page |
| `fn isSection()` | Bool | Whether this page defines a section (index.smd) |
| `fn asset(str)` | Asset | Get page asset |
| `fn site()` | Site | Parent site |
| `fn alternative(str)` | Alternative | Get alternative version |
| `fn isCurrent()` | Bool | Whether this is the current page |
| `fn wordCount()` | Int | Word count (chars / 5) |
| `fn toc()` | String | Rendered table of contents |
| `fn footnotes?()` | ?[Footnote] | Footnotes if any |
| `fn locale(str)` | Page | Page in different locale |
| `fn locale?(str)` | ?Page | Page in different locale (optional) |
| `fn locales()` | [Page] | All locale variants |

### Build

| Member | Type | Description |
|--------|------|-------------|
| `.generated` | Date | Build timestamp |
| `fn asset(str)` | Asset | Build-time asset |
| `fn git()` | Git | Git metadata (errors if not in repo) |
| `fn git?()` | ?Git | Git metadata (null if not in repo) |

### Git

| Member | Type | Description |
|--------|------|-------------|
| `.commit_hash` | String | Current commit hash |
| `.commit_date` | Date | Commit date |
| `.commit_message` | String | Commit message |
| `.author_name` | String | Author name |
| `.author_email` | String | Author email |
| `fn tag()` / `fn tag?()` | String / ?String | Current tag |
| `fn branch()` / `fn branch?()` | String / ?String | Current branch |

### Asset

| Method | Returns | Description |
|--------|---------|-------------|
| `fn link()` | String | URL to asset (also causes installation) |
| `fn size()` | Int | File size in bytes |
| `fn bytes()` | String | Raw file contents |
| `fn sriHash()` | String | Base64 SHA384 hash with `sha384-` prefix |
| `fn ziggy()` | any | Parse asset as Ziggy document |

### ContentSection

| Member | Type | Description |
|--------|------|-------------|
| `.id` | String | Section id |
| `.data` | Map | Data key-value pairs from SuperMD |
| `fn heading()` | String | Section heading as plain text |
| `fn heading?()` | ?String | Section heading (optional) |
| `fn html()` | String | Rendered section HTML |
| `fn htmlNoHeading()` | String | Rendered section HTML without heading |

### String

`fn len()` Int, `fn contains(str)` Bool, `fn startsWith(str)` Bool, `fn endsWith(str)` Bool, `fn eql(str)` Bool, `fn basename()` String, `fn suffix(str, ...)` String, `fn prefix(str, ...)` String, `fn fmt(str, ...)` String (replaces `{}` placeholders), `fn addPath(str, ...)` String (joins URL paths), `fn syntaxHighlight(str)` String, `fn parseInt()` Int, `fn parseDate()` Date, `fn splitN(str, int)` String, `fn lower()` String.

### Date

`fn gt(date)` Bool, `fn lt(date)` Bool, `fn eq(date)` Bool, `fn in(str)` Date (timezone), `fn add(int, str)` Date, `fn sub(int, str)` Date (units: `'second'`, `'minute'`, `'hour'`, `'day'`), `fn format(str)` String (Go-style: reference time is `Mon Jan 2 15:04:05 MST 2006`), `fn formatHTTP()` String.

### Bool

`fn then(str, ?str)` String (if true returns first arg, else second), `fn not()` Bool, `fn and(bool, ...)` Bool, `fn or(bool, ...)` Bool.

### Int

`fn eq(int)` Bool, `fn gt(int)` Bool, `fn plus(int)` Int, `fn div(int)` Int, `fn byteSize()` String (human-readable), `fn str()` String.

### Iterator (`$loop`)

| Member | Type | Description |
|--------|------|-------------|
| `.it` | any | Current item |
| `.idx` | Int | Current index |
| `.first` | Bool | True on first iteration |
| `.last` | Bool | True on last iteration |
| `.len` | Int | Total sequence length |
| `fn up()` | Iterator | Access outer loop |

### Array

`.len` Int, `.empty` Bool, `fn slice(int, ?int)` [any], `fn at(int)` any, `fn first?()` ?any, `fn last?()` ?any.

### Map (for `$page.custom` and `.data`)

`fn get(str)` any, `fn get?(str)` ?any, `fn getOr(str, str)` String, `fn has(str)` Bool, `fn iterate()` [KV], `fn iterPattern(str)` [KV].

KV: `.key` String, `.value` any.

### Error handling

All Scripty errors are unrecoverable. Use `?` variants of functions (e.g. `get?()`, `nextPage?()`, `git?()`) to get null instead of an error, then handle with `:if`.

## Asset system

**Site assets** (`assets/` directory): Shared across all pages. Referenced via `$site.asset('name')` in templates or `$image.siteAsset('name')` in content. Calling `.link()` installs the asset with a content-hashed filename.

**Page assets**: Files colocated with a page. For `blog/foo/index.smd`, assets live in `blog/foo/`. For `blog/bar.smd`, assets live in `blog/bar/`. Referenced via `$page.asset('name')` or `$image.asset('name')`.

**Build assets**: Generated by `build.zig` at build time. Referenced via `$build.asset('name')`.

**Static assets**: Listed in `zine.ziggy`'s `.static_assets` array. Served as-is without content hashing (useful for fonts, files that need stable URLs).

## Common patterns

### RSS feeds via alternatives

Section index defines an alternative layout:
```
---
.alternatives = [{
    .name = "rss",
    .layout = "blog.xml",
    .output = "index.xml",
}],
---
```

Link to RSS feed in content:
```
[RSS feed]($link.alternative('rss'))
```

Link from another page:
```
[Blog RSS]($link.page('blog').alternative('rss'))
```

RSS XML template:
```html
<rss version="2.0">
  <channel>
    <title :text="$site.title"></title>
    <link :text="$site.host_url"></link>
    <description :text="$site.title.suffix(' - Blog')"></description>
    <generator>Zine -- https://zine-ssg.io</generator>
    <language>en-US</language>
    <lastBuildDate :text="$build.generated.formatHTTP()"></lastBuildDate>
    <ctx :loop="$page.subpages()">
      <item>
        <title :text="$loop.it.title"></title>
        <description :text="$loop.it.content()"></description>
        <link :text="$site.host_url.addPath($loop.it.link())"></link>
        <pubDate :text="$loop.it.date.formatHTTP()"></pubDate>
        <guid :text="$site.host_url.addPath($loop.it.link())"></guid>
      </item>
    </ctx>
  </channel>
</rss>
```

### Devlog microblogging

Devlog pages use `$section` directives with ISO date ids for individual entries:

```
---
.title = "Devlog - 2024",
.date = @date("2024-01-01T00:00:00"),
.layout = "devlog.shtml",
---
[]($section.id('about'))
## About this Devlog
Description and RSS link here.

## [Entry Title]($section.id("2024-03-15T00:00:00"))
Entry content. Newest entries go at the top.

## [Older Entry]($section.id("2024-01-01T00:00:00"))
Another entry.
```

The devlog template renders sections individually, parsing dates from section ids:
```html
<section :loop="$page.contentSections().slice(1)">
    <article id="$loop.it.id">
        <time :text="$loop.it.id.parseDate().format('January 02, 2006')"></time>
        <h2><a href="$loop.it.id.prefix('#')" :html="$loop.it.heading()"></a></h2>
        <ctx :html="$loop.it.htmlNoHeading()"></ctx>
    </article>
</section>
```

The devlog RSS feed generates one item per section (not per page):
```html
<ctx :if="$page.subpages().first?()">
  <ctx :loop="$if.contentSections().slice(1)">
    <item>
      <title :text="$loop.it.heading()"></title>
      <description :text="$loop.it.html()"></description>
      <link :text="$site.host_url.addPath($page.link().suffix('#', $loop.it.id))"></link>
      <pubDate :text="$loop.it.id.parseDate().formatHTTP()"></pubDate>
    </item>
  </ctx>
</ctx>
```

### Prev/next navigation

```html
<nav :if="$page.prevPage?()">
    <a href="$if.link()">
        <span :text="$if.title"></span>
    </a>
</nav>
<nav :if="$page.nextPage?()">
    <a href="$if.link()">
        <span :text="$if.title"></span>
    </a>
</nav>
```

### Admonition blocks

```
># [NOTE]($block)
>The correct file extension for SuperHTML templates is `.shtml`.

># [WARNING]($block.attrs('warning'))
>This feature is experimental.
```

### Conditional rendering

```html
<ctx :if="$site.page('devlog').subpages().first?()">
    <a href="$if.link()">Devlog</a>
</ctx>
```

## CLI usage

- `zine` -- Start development server at `http://localhost:1990`. Watches files, auto-rebuilds, live-reloads browser. Assets served from memory.
- `zine release` -- Production build to `public/` directory. Does NOT clear output directory first; manually clear if needed.
- `zine help` -- Show all commands and options.
