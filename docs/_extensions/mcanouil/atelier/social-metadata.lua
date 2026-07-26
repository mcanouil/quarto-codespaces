--- Atelier - Social Metadata Filter
--- @module "social-metadata"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Emit the head tags Quarto's website machinery leaves out.
--- @description Quarto's `website.open-graph` covers title, description,
--- image, image dimensions, image alt, locale, and site name, and
--- `website.twitter-card` covers the Twitter equivalents. Neither emits
--- `og:type` or `og:url`, there is no canonical link, `<meta name="description">`
--- needs the pandoc `description-meta` variable that Quarto never populates,
--- and the icon and manifest links beyond `rel="icon"` have no configuration
--- key. This filter fills those gaps and nothing else.

--- Extension name constant
local EXTENSION_NAME = 'atelier'

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))

--- Link tags built from the configured paths, in head order.
--- `option` names the `extensions.atelier` key that supplies the `href`;
--- `type` and `sizes` are optional and emitted only when present.
--- @type table<integer, { option: string, rel: string, type: string?, sizes: string? }>
local ICON_LINKS = {
  { option = 'icon', rel = 'icon', type = 'image/svg+xml' },
  { option = 'apple-touch-icon', rel = 'apple-touch-icon', sizes = '180x180' },
  { option = 'manifest', rel = 'manifest' },
}

--- Colour schemes read from the `theme-color` option, in head order.
--- @type string[]
local THEME_COLOUR_SCHEMES = { 'light', 'dark' }

--- Stem of the page Quarto renders for missing paths. It is served from any
--- URL depth, so it must not claim a canonical URL of its own.
--- @type string
local NOT_FOUND_STEM = '404'

--- Stem of a directory index, served from its directory rather than from the
--- file itself.
--- @type string
local INDEX_STEM = 'index'

--- The input file, relative to the project root, with forward slashes.
--- @return string|nil The relative path, or nil outside a project context
local function project_relative_input()
  local project = quarto.project.directory
  local input = quarto.doc.input_file
  if not project or not input then
    return nil
  end
  return (pandoc.path.make_relative(input, project):gsub('\\', '/'))
end

--- Whether the page is the project's 404 page.
--- @param relative_input string The input path relative to the project root
--- @return boolean
local function is_not_found_page(relative_input)
  return relative_input:match('^' .. NOT_FOUND_STEM .. '%.%w+$') ~= nil
end

--- The page path as the site serves it, relative to the site root.
--- A directory index is served from its directory rather than from
--- `index.html`, and that is the URL a visitor lands on and the one a scraper
--- de-duplicates against, so `index.qmd` maps to the site root and
--- `<directory>/index.qmd` to `<directory>/`.
--- @param relative_input string The input path relative to the project root
--- @return string The served path, empty at the site root
local function served_path(relative_input)
  local stem = relative_input:gsub('%.%w+$', '')
  if stem == INDEX_STEM then
    return ''
  end
  local directory = stem:match('^(.*)/' .. INDEX_STEM .. '$')
  if directory then
    return directory .. '/'
  end
  return stem .. '.html'
end

--- Build the canonical URL for the page.
--- Uses `extensions.atelier.site-url`, because Quarto keeps the `website`
--- block out of the metadata it hands to Lua filters. Anchor the two together
--- in `_quarto.yml` so the URL is written once.
--- @param meta table The document metadata
--- @param relative_input string The input path relative to the project root
--- @return string|nil The absolute URL, or nil when `site-url` is unset
local function canonical_url(meta, relative_input)
  local site_url = meta_mod.get_metadata_value(meta, EXTENSION_NAME, 'site-url')
  if str.is_empty(site_url) then
    return nil
  end
  return (site_url:gsub('/+$', '')) .. '/' .. served_path(relative_input)
end

--- Render one `<link>` tag.
--- The `href` is written exactly as configured, relative to the site root.
--- Quarto's website resource resolver rewrites every `link[href]` it finds in
--- the rendered page, prefixing the page's own offset to the project root, so
--- adding one here too would double it on any page below the root. The 404
--- page is rewritten to a site-absolute path by the same pass.
--- @param link table<string, string> One entry of `ICON_LINKS`
--- @param href string The configured path, relative to the site root
--- @return string
local function link_tag(link, href)
  local attributes = { string.format('rel="%s"', link.rel) }
  if link.type then
    table.insert(attributes, string.format('type="%s"', link.type))
  end
  if link.sizes then
    table.insert(attributes, string.format('sizes="%s"', link.sizes))
  end
  table.insert(attributes, string.format('href="%s"', str.escape_attribute(href)))
  return '<link ' .. table.concat(attributes, ' ') .. '>'
end

--- Give pandoc a `description-meta` so it emits `<meta name="description">`.
--- Falls back to `subtitle`, which most pages carry; `description` wins when
--- both are set. Left alone when the document sets it itself.
--- @param meta table The document metadata, modified in place
--- @return nil
local function set_description_meta(meta)
  if meta['description-meta'] then
    return
  end
  local source = meta.description or meta.subtitle
  if source then
    meta['description-meta'] = pandoc.MetaString(str.stringify(source))
  end
end

--- Collect the icon and manifest link tags for the page.
--- @param config table|nil The `extensions.atelier` configuration table
--- @return table<integer, string>
local function icon_tags(config)
  local tags = {}
  if not config then
    return tags
  end
  for _, link in ipairs(ICON_LINKS) do
    local href = config[link.option] and str.stringify(config[link.option])
    if not str.is_empty(href) then
      table.insert(tags, link_tag(link, href))
    end
  end
  return tags
end

--- Collect the `theme-color` tags for the page.
--- @param config table|nil The `extensions.atelier` configuration table
--- @return table<integer, string>
local function theme_colour_tags(config)
  local tags = {}
  local colours = config and config['theme-color']
  if not colours then
    return tags
  end
  for _, scheme in ipairs(THEME_COLOUR_SCHEMES) do
    local colour = colours[scheme] and str.stringify(colours[scheme])
    if not str.is_empty(colour) then
      table.insert(
        tags,
        string.format(
          '<meta name="theme-color" content="%s" media="(prefers-color-scheme: %s)">',
          str.escape_attribute(colour),
          scheme
        )
      )
    end
  end
  return tags
end

--- @param meta table The document metadata
--- @return table|nil
local function social_metadata(meta)
  if not quarto.doc.is_format('html:js') then
    return nil
  end

  set_description_meta(meta)

  local relative_input = project_relative_input()
  if not relative_input then
    log.log_warning(EXTENSION_NAME, 'No project context; skipping the social metadata head tags.')
    return meta
  end

  local config = meta_mod.get_extension_config(meta, EXTENSION_NAME)
  local tags = { '<meta property="og:type" content="website">' }

  if not is_not_found_page(relative_input) then
    local url = canonical_url(meta, relative_input)
    if url then
      local escaped = str.escape_attribute(url)
      table.insert(tags, string.format('<meta property="og:url" content="%s">', escaped))
      table.insert(tags, string.format('<link rel="canonical" href="%s">', escaped))
    end
  end

  for _, tag in ipairs(theme_colour_tags(config)) do
    table.insert(tags, tag)
  end

  for _, tag in ipairs(icon_tags(config)) do
    table.insert(tags, tag)
  end

  quarto.doc.include_text('in-header', table.concat(tags, '\n'))

  return meta
end

return {
  { Meta = social_metadata }
}
