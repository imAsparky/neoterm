-- lua/neoterm/keymaps.lua
local M = {}

-- Store all our keymaps in one place
M.maps = {
  -- Base group
  base = {
    name = '[N]eoterm',
    prefix = '<leader>n',
    t = { cmd = ':Neoterm<CR>', desc = 'Floating Terminal' },
  },
  -- Command groups from commands.lua
  groups = {
    a = { name = 'Run a bash alias' },
    c = { name = 'Edit configuration' },
    d = { name = 'Django commands' },
    v = { name = 'Virtual environment' },
  },
  -- Individual commands
  commands = {
    -- Will be populated from commands.term_commands
  },
  -- Utility commands
  utils = {
    c = { cmd = ':NeotermCleanup<CR>', desc = 'Cleanup configuration' },
  },
}

function M.setup()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return
  end

  -- Register base group
  wk.add {
    { M.maps.base.prefix, name = M.maps.base.name },
    { M.maps.base.prefix .. 't', M.maps.base.t.cmd, desc = M.maps.base.t.desc, mode = 'n' },
  }

  -- Register command groups
  for prefix, group_info in pairs(M.maps.groups) do
    wk.add {
      { M.maps.base.prefix .. prefix, group = group_info.name, mode = 'n' },
    }
  end

  -- Register utility commands
  for key, cmd_info in pairs(M.maps.utils) do
    wk.add {
      { M.maps.base.prefix .. key, cmd_info.cmd, desc = cmd_info.desc, mode = 'n' },
    }
  end
end

-- Function to register command mappings
function M.register_command(name, command)
  -- Use the specified keys or fall back to first letter of command name
  local key_sequence = command.keys or name:sub(1, 1)
  M.maps.commands[key_sequence] = {
    cmd = ':Neoterm' .. name:upper() .. '<CR>',
    desc = command.desc,
  }
end

-- Function to setup command mappings
function M.setup_command_mappings()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return
  end

  for key, cmd_info in pairs(M.maps.commands) do
    wk.add {
      { M.maps.base.prefix .. key, cmd_info.cmd, desc = cmd_info.desc, mode = 'n' },
    }
  end
end

return M
