local M = {}
local health = vim.health or require 'health'
local config = require 'neoterm.config'

-- Function to get the actual leader key setting
local function get_leader_display()
  local leader = vim.g.mapleader
  if leader == ' ' then
    return '<Space>'
  elseif type(leader) == 'string' then
    return '<' .. leader .. '>'
  else
    return '<Leader>' -- default if not set
  end
end

-- Check if there are any mappings starting with leader + prefix
local function check_prefix_mappings(prefix)
  local leader = get_leader_display()
  local mapping = leader .. prefix

  -- Get all mappings and filter for ones starting with our prefix
  local all_maps = vim.fn.execute 'verbose map'
  local existing_mappings = {}

  -- Split into lines and process each mapping
  for line in vim.gsplit(all_maps, '\n') do
    -- Look for lines that start with a mode character (n, v, x, s, o, i, l, c, t)
    if line:match '^[nvxsoilct]%s+' then
      -- If this mapping starts with our prefix
      if line:match(mapping) then
        table.insert(existing_mappings, line)
      end
    end
  end

  return #existing_mappings > 0, table.concat(existing_mappings, '\n')
end

-- Comprehensive version check function
local function check_version()
  local version = vim.version()
  local required = { 0, 10, 0 }
  -- First check actual version numbers
  local version_ok = version.major > required[1] or (version.major == required[1] and version.minor >= required[2])
  if version_ok then
    health.ok(string.format('Neovim version %d.%d.%d meets requirements', version.major, version.minor, version.patch))
  else
    health.error(
      string.format(
        'Neovim version %d.%d.%d does not meet minimum requirement of %d.%d.%d',
        version.major,
        version.minor,
        version.patch,
        required[1],
        required[2],
        required[3]
      )
    )
  end
end

function M.check()
  health.start 'neoterm'

  -- Check version requirements
  check_version()

  -- Check leader key setting
  local leader_display = get_leader_display()
  health.info(string.format('Leader key is set to: %s', leader_display))

  -- Check for which-key.nvim
  local has_which_key = pcall(require, 'which-key')
  if has_which_key then
    health.ok 'which-key.nvim is installed'
  else
    health.warn 'which-key.nvim is not installed (recommended for keymaps)'
  end

  -- Check prefix mappings
  local prefix = (config.options.key_prefix or 'n'):lower()
  local has_mappings, existing_mappings = check_prefix_mappings(prefix)

  if has_mappings then
    health.info(string.format("Found existing mappings starting with '%s%s'. Current mappings:\n%s", get_leader_display(), prefix, existing_mappings))
  else
    health.ok(string.format("No existing mappings found for '%s%s'", get_leader_display(), prefix))
  end

  -- Check terminal capabilities (Neovim specific)
  if vim.fn.executable 'nvim' == 1 then
    -- In Neovim, terminal is always available if these functions exist
    if vim.fn.exists '*termopen' == 1 and vim.fn.exists '*jobstart' == 1 then
      health.ok 'Terminal support available'
    else
      health.error 'Terminal support not available'
    end
  else
    health.error 'Not running in Neovim'
  end
end

return M
