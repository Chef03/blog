# Notebook — a Hugo blog

A self-contained Hugo site with a dark desktop sidebar, a year-grouped post archive, and a compact mobile header. Inspired by [McLuhan by Anders Norén](https://mcluhan.andersnoren.se/), with original templates and styles. No tags, categories, related posts, or comments.

## Publish with GitHub Pages

This repository is configured for **https://chef03.github.io/blog/**. The GitHub repository must be named `blog`; rename it under **Settings → General → Repository name** if it still has its original name.

1. In the GitHub repository, open **Settings → Pages** and choose **GitHub Actions** as the build and deployment source.
2. Commit the site sources and `.github/workflows/pages.yml`, then push to `main`.
3. Check **Actions → Build and deploy Hugo to GitHub Pages** for the build and deployment result.

Every push to `main` rebuilds and deploys the site. You can also run the workflow manually from the Actions tab. The workflow installs Hugo **0.168.0**, builds into a fresh temporary directory, and uploads only the generated website. Keep `public/`, `.tools/`, and `resources/` out of Git.

For the first commit, run these commands from this repository's directory:

```sh
git add .
git commit -m "Configure Hugo blog for GitHub Pages"
git push -u origin main
```

The workflow reads the deployment URL from GitHub Pages, so it also supports a custom domain configured there. Update `baseURL` in `hugo.toml` to match if you change the domain. Local images, cover images, figures, videos, and theme assets account for the `/blog/` prefix automatically.

## Run

Install [Hugo](https://gohugo.io/installation/) **0.168.0** to match the deployment workflow. The standard edition is sufficient; no Node, package installation, or external theme checkout is needed.

From this directory:

```sh
hugo server
```

Open <http://localhost:1313/>. Include draft posts with `hugo server -D`.

On Windows, the convenience script also finds the development binary in `.tools/hugo/` if Hugo is not on your PATH:

```powershell
./blog.ps1 serve
./blog.ps1 serve -Drafts
```

This repository's root is the Hugo site directory; run the commands above directly from it.

## Write a post

```sh
hugo new content posts/my-first-post.md
```

Or on Windows:

```powershell
./blog.ps1 new -Path posts/my-first-post.md
```

Edit the generated file in `content/posts/`. Set `draft: false` when it is ready to publish. Drafts and future-dated posts are excluded from production builds by default.

```yaml
---
title: 'My first post'
date: '2026-10-14T10:00:00+02:00'
draft: false
description: 'A short description for search engines and feeds.'
---

Write your **Markdown** here.
```

Markdown supports headings, links, images, blockquotes, lists, task lists, tables, footnotes, and syntax-highlighted fenced code. For images, place `diagram.png` under `static/images/` and use `![Description](/images/diagram.png)` for a site hosted at the domain root. For portable post images, use a page bundle (`content/posts/my-post/index.md` and an adjacent `diagram.png`), then `![Description](diagram.png)`.

Posts with level-two or level-three headings automatically show a floating table-of-contents control at the bottom right, available throughout the post. Selecting a section closes the panel; Escape also closes it. Set `toc: false` in a post's front matter to hide it.

## Videos

Place an MP4 clip under `static/videos/`, then embed it in a post:

```text
{{< video src="/videos/forest-follies.mp4" caption="The agent attempting Forest Follies." >}}
```

Use an H.264-encoded MP4 for broad browser support. An optional `poster="/images/preview.png"` parameter sets the image shown before playback. Videos have playback controls and fit the article width.

## LaTeX mathematics

KaTeX 0.18.4 and its fonts are bundled locally. Equations work without an external CDN. Hugo preserves their delimiters through its Goldmark passthrough extension.

Inline:

```latex
The update is \(\theta_{t+1} = \theta_t - \alpha\nabla L\).
You can also write $E = mc^2$.
```

Display:

```latex
$$
G_t = \sum_{k=0}^{T-t-1} \gamma^k r_{t+k+1}
$$

\[
\int_0^1 x^2\,dx = \frac{1}{3}
\]
```

Paired dollar signs are interpreted as math delimiters. Put literal currency amounts in inline code (for example, `$5`) to avoid accidental equation parsing. Code blocks are left untouched. This supports KaTeX's mathematical LaTeX syntax, rather than full LaTeX documents or arbitrary packages.

Math is enabled on all content pages by default; set `math: false` in a page's front matter to omit its scripts and stylesheet. Alternatively set `params.math = false` in `hugo.toml` and enable individual posts with `math: true`.

## Make it yours

- Set `title`, `baseURL`, and `params.description` in `hugo.toml`.
- Edit the homepage introduction in `content/_index.md`.
- Replace `content/about.md` with your own introduction.
- Replace the five example posts in `content/posts/`.
- Edit `menus.main` in `hugo.toml` to change sidebar links.
- Adjust the theme styles in `themes/notebook/assets/css/main.css`.

The home page and `/posts/` list every published post, newest first, grouped by year. An RSS feed is available at `/index.xml`. No taxonomies are generated, even if a post contains tag or category metadata.

## Build and deploy

Set `baseURL` to your real site URL (including any subdirectory, such as `https://example.org/blog/`) before building:

```sh
hugo --minify
```

Or `./blog.ps1 build`. Upload the contents of `public/` to any static host. You can also override the URL at build time:

```sh
hugo --minify --baseURL https://example.org/blog/
```

The `public/`, `resources/`, and `.tools/` directories are ignored by Git. All theme assets needed for the site, including KaTeX, are tracked. No hosting account is required to generate or preview the site.

## Files

```text
blog/
  hugo.toml             Site identity, menus, Markdown and math configuration
  archetypes/posts.md    Default front matter for new posts
  content/              Markdown pages and posts
  themes/notebook/      Local theme: templates, CSS, and math assets
  blog.ps1              Optional Windows commands
```

The original theme code is MIT licensed; see `themes/notebook/LICENSE`. The bundled KaTeX license is in `themes/notebook/static/vendor/katex/LICENSE`.
