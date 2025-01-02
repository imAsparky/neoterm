-- lua/neoterm/keymaps.lua
local M = {}
local config = require 'neoterm.config'
local utils = require 'neoterm.utils'

-- Function to register individual command
function M.register_command(name, command)
  -- Use the specified keys or fall back to first letter of command name
  local key_sequence = command.keys or name:sub(1, 1)
  M.maps.commands[key_sequence] = {
    cmd = ':' .. utils.format_command_name(name) .. '<CR>',
    desc = command.desc,
  }
end

function M.setup()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return
  end

  -- Store base keymap configuration
  M.base = {
    name = '[N]eoterm',
    prefix = '<leader>' .. config.options.key_prefix,
    t = { cmd = ':Neoterm<CR>', desc = 'Neoterm Terminal' },
  }

  M.maps = {
    commands = {}, -- Will store registered commands
  }

  -- Register base group
  wk.add {
    { M.base.prefix, name = M.base.name },
    { M.base.prefix .. 't', M.base.t.cmd, desc = M.base.t.desc, mode = 'n' },
  }

  -- Register groups
  for group_key, group_info in pairs(config.options.groups) do
    wk.add {
      { M.base.prefix .. group_key, group = group_info.name, mode = 'n' },
    }
  end
end

-- Function to register command mappings
function M.setup_command_mappings()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return
  end

  -- Register all commands from config
  for name, cmd_info in pairs(config.options.commands) do
    -- Use the specified keys or fall back to first letter of command name
    local key_sequence = cmd_info.keys or name:sub(1, 1)
    wk.add {
      { M.base.prefix .. key_sequence, ':' .. utils.format_command_name(name) .. '<CR>', desc = cmd_info.desc, mode = 'n' },
    }
  end
end

return M
