--[[
Generate the configuration reference from the repository itself.

The `.devcontainer/` directory gains a new `quarto-<version>` configuration
every time Quarto releases a minor version, and every place that lists those
versions by hand drifts the moment one is added. This filter reads the
directory at render time and fills in:

  - `::: {#devcontainer-configurations}`, replaced by the configuration table;
  - `[]{.version-range}`, replaced by "`<first>` … `<last>`";
  - `[]{.version-latest}`, replaced by the highest version.

Both spans accept a `suffix` attribute, appended inside the code spans, so
`[]{.version-range suffix="-noble"}` renders "`1.0-noble` … `1.10-noble`".
]]

local IMAGE = "`quarto-codespaces:latest`"

--- Compare two dotted version strings numerically, so 1.10 sorts after 1.9.
local function version_less_than(a, b)
  local a_major, a_minor = a:match("^(%d+)%.(%d+)$")
  local b_major, b_minor = b:match("^(%d+)%.(%d+)$")
  if tonumber(a_major) ~= tonumber(b_major) then
    return tonumber(a_major) < tonumber(b_major)
  end
  return tonumber(a_minor) < tonumber(b_minor)
end

--- Locate `.devcontainer/`. Pandoc runs with the input file's directory as the
--- working directory, so search from the project root and then walk upwards.
local function devcontainer_directory()
  local candidates = {}
  local project = os.getenv("QUARTO_PROJECT_DIR")
  if project then
    table.insert(candidates, project .. "/../.devcontainer")
    table.insert(candidates, project .. "/.devcontainer")
  end
  local prefix = ""
  for _ = 1, 4 do
    table.insert(candidates, prefix .. ".devcontainer")
    prefix = prefix .. "../"
  end

  for _, candidate in ipairs(candidates) do
    local ok, entries = pcall(pandoc.system.list_directory, candidate)
    if ok and entries then
      return candidate, entries
    end
  end
  return nil, nil
end

--- Version-pinned configurations, sorted from newest to oldest.
local function pinned_versions()
  local _, entries = devcontainer_directory()
  if not entries then
    quarto.log.warning("[devcontainer-configurations] .devcontainer/ not found; leaving the placeholder in place")
    return {}
  end

  local versions = {}
  for _, entry in ipairs(entries) do
    local version = entry:match("^quarto%-(%d+%.%d+)$")
    if version then
      table.insert(versions, version)
    end
  end
  table.sort(versions, function(a, b)
    return version_less_than(b, a)
  end)
  return versions
end

local function row(path, name, image, quarto_version)
  return string.format("| `%s` | %s | %s | %s |", path, name, image, quarto_version)
end

local function configuration_table()
  local versions = pinned_versions()
  if #versions == 0 then
    return nil
  end

  local rows = {
    "| Path | Name | Base | Quarto |",
    "| --- | --- | --- | --- |",
    row(".devcontainer/devcontainer.json", "Release", IMAGE, "`release`"),
    row(".devcontainer/quarto-prerelease/devcontainer.json", "Pre-release", IMAGE, "`prerelease`"),
  }
  for _, version in ipairs(versions) do
    table.insert(
      rows,
      row(
        string.format(".devcontainer/quarto-%s/devcontainer.json", version),
        version,
        IMAGE,
        string.format("`%s`", version)
      )
    )
  end
  table.insert(rows, row(".devcontainer/universal/devcontainer.json", "Universal", "`devcontainers/universal:latest`", "`release`"))
  table.insert(rows, row(".github/.devcontainer/devcontainer.json", "Build recipe", "`buildpack-deps:noble-curl`", "build argument"))

  return pandoc.read(table.concat(rows, "\n"), "markdown").blocks
end

function Div(div)
  if div.identifier ~= "devcontainer-configurations" then
    return nil
  end
  local blocks = configuration_table()
  if not blocks then
    return nil
  end
  div.identifier = ""
  div.content = blocks
  return div
end

function Span(span)
  local is_range = span.classes:includes("version-range")
  local is_latest = span.classes:includes("version-latest")
  if not (is_range or is_latest) then
    return nil
  end

  local versions = pinned_versions()
  if #versions == 0 then
    return nil
  end

  local suffix = span.attributes["suffix"] or ""
  if is_latest then
    return pandoc.Code(versions[1] .. suffix)
  end
  return pandoc.Inlines({
    pandoc.Code(versions[#versions] .. suffix),
    pandoc.Str(" … "),
    pandoc.Code(versions[1] .. suffix),
  })
end
