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

-- Get all existing leader prefixes using built-in functions
local function get_used_prefixes()
  local used = {}
  local leader = get_leader_display()

  -- For each possible letter, check if it's mapped
  for letter in string.gmatch('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', '.') do
    local mapping = leader .. letter
    -- First check if there's an exact mapping
    local map_info = vim.fn.maparg(mapping, 'n', false, true)

    -- Then check if there are any mappings starting with this prefix
    local has_prefix = vim.fn.mapcheck(mapping, 'n') ~= ''

    if map_info.lhs or has_prefix then
      used[letter:lower()] = map_info.desc or map_info.rhs or 'has mappings'
    end
  end

  return used
end

-- Find available prefixes
local function get_available_prefixes(used_prefixes)
  local available = {}
  -- Create list of common prefixes that might make sense for a terminal
  local preferred = { 't', 'T', 'e', 'x', 'm', 'n', 'r', 'c' }

  -- First check preferred prefixes
  for _, prefix in ipairs(preferred) do
    if not used_prefixes[prefix:lower()] then
      table.insert(available, prefix)
    end
  end

  -- If we need more suggestions, check other letters
  if #available < 3 then
    for letter in string.gmatch('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', '.') do
      if not used_prefixes[letter:lower()] and not vim.tbl_contains(available, letter) then
        table.insert(available, letter)
        if #available >= 5 then -- Limit to 5 total suggestions
          break
        end
      end
    end
  end

  return available
end

function M.check()
  health.start 'neoterm'

  -- Check Neovim version
  if vim.fn.has 'nvim-0.8.0' == 1 then
    health.ok 'Neovim version >= 0.8.0'
  else
    health.error 'Neovim version must be >= 0.8.0'
  end

  -- Check leader key setting
  local leader_display = get_leader_display()
  health.info(string.format('Leader key is set to: %s', leader_display))

  -- Check for which-key.nvim
  local has_which_key = pcall(require, 'which-key')
  if has_which_key then
    health.ok 'which-key.nvim is installed'
  else
    health.warn 'which-key.nvim is not installed (required for keymaps)'
  end

  -- Check prefix availability
  local prefix = (config.options.key_prefix or 'n'):lower()
  local used_prefixes = get_used_prefixes()

  if used_prefixes[prefix] then
    local suggestions = get_available_prefixes(used_prefixes)
    if #suggestions > 0 then
      health.warn(
        string.format(
          "Prefix '%s%s' is already mapped to: %s\nAvailable alternatives: %s\nAdd\nopts = {\nkey_prefix = '<prefix>'\n}\nin your setup options to change, where prefix is one of the alternative options listed above,\nor another letter you know is not used.",
          get_leader_display(),
          prefix,
          used_prefixes[prefix],
          table.concat(suggestions, ', ')
        )
      )
    else
      health.warn(
        string.format(
          "Prefix '%s%s' is already mapped to: %s\nConsider changing key_prefix in setup options",
          get_leader_display(),
          prefix,
          used_prefixes[prefix]
        )
      )
    end
  else
    health.ok(string.format("Prefix '%s%s' is available", get_leader_display(), prefix))
  end

  -- Check terminal capabilities (Neovim specific)
  if vim.fn.executable 'nvim' == 1 then
    -- In Neovim, terminal is always available if these functions exist
    if vim.fn.exists '*termopen' == 1 and vim.fn.exists '*jobstart' == 1 then
      health.ok 'Terminal support available'
    else
      health.error 'Terminal support not available;swe'
    end
  else
    health.error 'Not running in Neovim'
  end
end

return M
