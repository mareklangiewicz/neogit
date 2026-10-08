local logger = require("neogit.logger")
local config = require("neogit.config")
local Path = require("neogit.lib.path")

---@class NeogitState
---@field loaded boolean
---@field _enabled boolean
---@field state table
---@field path NeogitPath|nil file of the project last synced, see M.sync()
---@field config NeogitConfig
local M = {}

M.loaded = false

local function log(message)
  logger.debug(string.format("[STATE]: %s: '%s'", message, M.path:absolute()))
end

---The directory persisted settings are scoped to: the root of the repository neogit is
---working on, or, outside of one, the current working directory. Resolved on every access,
---so opening a second repository in the same session doesn't reuse the first one's settings.
---@return string
function M.project_dir()
  local root = require("neogit.lib.git").repo.worktree_root
  if root == nil or root == "" then
    root = vim.uv.cwd()
  end

  return root
end

---@param config NeogitConfig
---@param dir? string project directory, defaults to M.project_dir()
---@return NeogitPath
function M.filepath(config, dir)
  local state_path = Path:new(vim.fn.stdpath("state")):joinpath("neogit")
  local filename = "state"

  if config.use_per_project_settings then
    filename = (dir or M.project_dir()):gsub("^(%a):", "/%1"):gsub("/", "%%"):gsub(Path.path.sep, "%%")
  end

  return state_path:joinpath(filename)
end

---Initializes state. The file itself is picked and read lazily, on first use.
---@param config NeogitConfig
function M.setup(config)
  if M.loaded then
    return
  end

  M.config = config
  M._enabled = config.remember_settings
  M.path = nil
  M.state = {}
  M.loaded = true
end

---Points state at the current project's file, re-reading it when the project changed.
function M.sync()
  if not M.loaded then
    return
  end

  local path = M.filepath(M.config)
  if M.path and M.path:absolute() == path:absolute() then
    return
  end

  M.path = path
  M.state = M.read()
  log("Loaded")
end

---@return boolean
function M.enabled()
  return M.loaded and M._enabled
end

---Reads state from disk
---@return table
function M.read()
  if not M.enabled then
    return {}
  end

  if not M.path:exists() then
    log("Creating file")
    M.path:touch { parents = true }
    M.path:write(vim.mpack.encode {}, "w")
  end

  log("Reading file")
  local content = M.path:read()
  if content then
    return vim.mpack.decode(content)
  else
    return {}
  end
end

---Writes state to disk
function M.write()
  if not M.enabled() then
    return
  end

  log("Writing file")
  M.path:write(vim.mpack.encode(M.state), "w")
end

---Construct a cache-key from a table
---@param key_table table
---@return string
local function gen_key(key_table)
  return table.concat(key_table, "--")
end

---Set option and write to disk
---@param key string[]
---@param value any
function M.set(key, value)
  if not M.enabled() then
    return
  end

  M.sync()

  local cache_key = gen_key(key)
  if not vim.tbl_contains(config.values.ignored_settings, cache_key) then
    if value == "" then
      M.state[cache_key] = nil
    else
      M.state[cache_key] = value
    end

    M.write()
  end
end

---Get option. If value isn't set, return provided default.
---@param key table
---@param default any
---@return any
function M.get(key, default)
  if not M.enabled() then
    return default
  end

  M.sync()

  local value = M.state[gen_key(key)]
  if value ~= nil then
    return value
  else
    return default
  end
end

---Reset current state, removing whats written to disk
function M._reset()
  M.sync()
  log("Reset file")
  M.path:write(vim.mpack.encode {}, "w")
  M.state = {}
end

return M
