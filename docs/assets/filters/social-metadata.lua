--- @module social-metadata
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
---
--- Emit the head tags Quarto's website machinery does not.
---
--- `website.open-graph` covers title, description, image, image dimensions,
--- image alt, locale, and site name, and `website.twitter-card` covers the
--- Twitter equivalents. Neither emits `og:type` or `og:url`, there is no
--- canonical link, and `<meta name="description">` needs the pandoc
--- `description-meta` variable, which Quarto never populates. The icon and
--- manifest links beyond `rel="icon"` have no configuration key either.
---
--- This filter fills exactly those gaps:
---
---   - `description-meta`, from `description` or `subtitle`, so every page
---     gets a plain description tag;
---   - `og:type`, `og:url`, and `<link rel="canonical">`, built from the
---     top-level `site-url`, in the same form as the generated sitemap;
---   - the SVG icon, Apple touch icon, and manifest links, plus `theme-color`.
---
--- Paths are written relative to the page, so they resolve under
--- `quarto preview` at the server root as well as under the deployed
--- `/quarto-codespaces/` prefix. On `404.html` Quarto rewrites them to
--- site-absolute paths itself, since a 404 is served from any depth.

--- Icon and manifest links, in head order. `href` is relative to the site root.
--- @type table<integer, table<string, string>>
local ICON_LINKS = {
  { rel = "icon", type = "image/svg+xml", href = "assets/icons/icon.svg" },
  { rel = "apple-touch-icon", sizes = "180x180", href = "assets/icons/apple-touch-icon.png" },
  { rel = "manifest", href = "site.webmanifest" },
}

--- Browser chrome colours, from the brand palette: frost and midnight.
--- @type table<integer, table<string, string>>
local THEME_COLOURS = {
  { colour = "#F5F7FA", scheme = "light" },
  { colour = "#0B1220", scheme = "dark" },
}

--- The 404 page is served for any missing path, so it must not claim a
--- canonical URL of its own.
--- @type table<string, boolean>
local NO_CANONICAL = { ["404.qmd"] = true }

--- Escape a value for use inside a double-quoted HTML attribute.
--- @param value string The raw attribute value
--- @return string
local function escape_attribute(value)
  return value
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
end

--- The input file, relative to the project root, with forward slashes.
--- @return string|nil The relative path, or nil outside a project context
local function project_relative_input()
  local project = quarto.project.directory
  local input = quarto.doc.input_file
  if not project or not input then
    return nil
  end
  return (pandoc.path.make_relative(input, project):gsub("\\", "/"))
end

--- The `../` steps that separate the page from the site root.
--- Empty at the root, so hrefs stay free of a redundant `./`: Quarto prefixes
--- the site path on `404.html`, and `/quarto-codespaces/./icon.svg` is ugly.
--- @param relative_input string The input path relative to the project root
--- @return string The offset, with a trailing slash, or an empty string
local function offset_to_root(relative_input)
  local steps = {}
  for _ in relative_input:gmatch("/") do
    table.insert(steps, "..")
  end
  if #steps == 0 then
    return ""
  end
  return table.concat(steps, "/") .. "/"
end

--- Build the canonical URL for the page.
--- Uses the top-level `site-url`, which `_quarto.yml` anchors to
--- `website.site-url`; the `website` block itself never reaches Lua.
--- @param meta table The document metadata
--- @param relative_input string The input path relative to the project root
--- @return string|nil The absolute URL, or nil when `site-url` is unset
local function canonical_url(meta, relative_input)
  if not meta["site-url"] then
    return nil
  end
  local site_url = pandoc.utils.stringify(meta["site-url"]):gsub("/+$", "")
  local page = relative_input:gsub("%.%w+$", ".html")
  return site_url .. "/" .. page
end

--- Render one `<link>` tag.
--- @param link table<string, string> One entry of `ICON_LINKS`
--- @param offset string The offset to the site root, with a trailing slash
--- @return string
local function link_tag(link, offset)
  local attributes = { string.format('rel="%s"', link.rel) }
  if link.type then
    table.insert(attributes, string.format('type="%s"', link.type))
  end
  if link.sizes then
    table.insert(attributes, string.format('sizes="%s"', link.sizes))
  end
  table.insert(attributes, string.format('href="%s%s"', offset, link.href))
  return "<link " .. table.concat(attributes, " ") .. ">"
end

--- Give pandoc a `description-meta` so it emits `<meta name="description">`.
--- Every page here carries a subtitle; `description` wins when both are set.
--- @param meta table The document metadata, modified in place
--- @return nil
local function set_description_meta(meta)
  if meta["description-meta"] then
    return
  end
  local source = meta.description or meta.subtitle
  if source then
    meta["description-meta"] = pandoc.MetaString(pandoc.utils.stringify(source))
  end
end

--- @param meta table The document metadata
--- @return table|nil
function Meta(meta)
  if not quarto.doc.is_format("html:js") then
    return nil
  end

  set_description_meta(meta)

  local relative_input = project_relative_input()
  if not relative_input then
    quarto.log.warning("[social-metadata] no project context; skipping the head tags")
    return meta
  end

  local offset = offset_to_root(relative_input)
  local tags = { '<meta property="og:type" content="website">' }

  if not NO_CANONICAL[relative_input] then
    local url = canonical_url(meta, relative_input)
    if url then
      local escaped = escape_attribute(url)
      table.insert(tags, string.format('<meta property="og:url" content="%s">', escaped))
      table.insert(tags, string.format('<link rel="canonical" href="%s">', escaped))
    end
  end

  for _, theme in ipairs(THEME_COLOURS) do
    table.insert(
      tags,
      string.format(
        '<meta name="theme-color" content="%s" media="(prefers-color-scheme: %s)">',
        theme.colour,
        theme.scheme
      )
    )
  end

  for _, link in ipairs(ICON_LINKS) do
    table.insert(tags, link_tag(link, offset))
  end

  quarto.doc.include_text("in-header", table.concat(tags, "\n"))

  return meta
end
