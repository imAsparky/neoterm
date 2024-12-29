-- lua/neoterm/commands.lua
local M = {}
local config = require 'neoterm.config'

-- Predefined terminal commands
M.term_commands = {
  -- Bash alias group
  ebal = {
    cmd = 'ebal',
    desc = 'Edit bash alias',
    keys = 'aa',
    group = 'a',
  },
  ebrc = {
    cmd = 'ebrc',
    desc = 'Edit bash rc',
    keys = 'ar',
    group = 'e',
  },
  -- Virtual environment group
  venvp = {
    cmd = function()
      return {
        init = vim.o.shell,
        post_cmd = string.format('cd ../ && source %s/bin/activate && cd -', config.options.venv_name),
      }
    end,
    desc = 'Activate a virtual environment located in parent directory',
    keys = 'vp',
    group = 'v',
  },
  venvw = {
    cmd = function()
      return {
        init = vim.o.shell,
        post_cmd = string.format('source %s/bin/activate', config.options.venv_name),
      }
    end,
    desc = 'Activate a virtual environment located in working directory',
    keys = 'vw',
    group = 'v',
  },
  -- Config group
  conf = {
    cmd = config.configure_venv,
    desc = 'Configure virtual environment folder name',
    keys = 'cn',
    group = 'c',
    no_term = true,
  },
}

-- Command groups configuration
M.command_groups = {
  a = { name = 'Run a bash alias' },
  c = { name = 'Edit configuration' },
  d = { name = 'Django commands' },
  v = { name = 'Virtual environment' },
}

-- Function to set up the which-key mappings
function M.setup_which_key()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    -- Create base group mapping
    wk.add {
      { '<leader>n', name = '[N]eoterm' },
      { '<leader>nt', ':Neoterm<CR>', desc = 'Floating Terminal', mode = 'n' },
    }

    -- Register command groups
    for prefix, group_info in pairs(M.command_groups) do
      wk.add {
        { '<leader>n' .. prefix, group = group_info.name, mode = 'n' },
      }
    end

    -- Create mappings for each command
    for name, cmd in pairs(M.term_commands) do
      -- Use the specified keys or fall back to first letter of command name
      local key_sequence = cmd.keys or name:sub(1, 1)
      wk.add {
        { '<leader>n' .. key_sequence, ':Neoterm' .. name:upper() .. '<CR>', desc = cmd.desc, mode = 'n' },
      }
    end
  end
end

return M
