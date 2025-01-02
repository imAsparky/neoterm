-- lua/neoterm/command_registry.lua
local M = {}

local config = require 'neoterm.config'
local keymaps = require 'neoterm.keymaps'
local terminal = require 'neoterm.terminal'
local utils = require 'neoterm.utils'

-- Function to process commands and groups from config
function M.process_config()
  -- Get the merged config (defaults + user config)
  local current_config = config.options
  -- Process all commands and register them with the keymap module
  if current_config.commands then
    for name, command in pairs(current_config.commands) do
      -- Debug command structure
      -- vim.notify(
      --   string.format('Processing command %s:\n  cmd type: %s\n  full command: %s', name, type(command.cmd), vim.inspect(command)),
      --   vim.log.levels.INFO
      -- )

      -- Register keymap
      keymaps.register_command(name, command)
      -- Create valid command name
      local cmd_name = utils.format_command_name(name)
      -- Create Vim command
      vim.api.nvim_create_user_command(cmd_name, function()
        local cmd_config = type(command.cmd) == 'function' and command.cmd() or command.cmd
        -- Debug cmd_config
        -- vim.notify(
        --   string.format('Executing command %s:\n  cmd_config type: %s\n  cmd_config: %s', name, type(cmd_config), vim.inspect(cmd_config)),
        --   vim.log.levels.INFO
        -- )
        -- If it's a direct function wrapped in a table, execute it
        if type(cmd_config) == 'table' and type(cmd_config.cmd) == 'function' then
          cmd_config.cmd()
          -- Otherwise treat as terminal command
        else
          terminal.run_command(name)
        end
      end, {
        desc = command.desc,
      })
    end
  end
end

-- Main setup function
function M.setup()
  vim.api.nvim_create_user_command('Neoterm', function()
    require('neoterm.terminal').toggle()
  end, {
    desc = 'Toggle Neoterm terminal window',
  })
  -- Set up base keymaps
  keymaps.setup()
  -- Process commands from config and set up their keymaps
  M.process_config()
  -- Set up command mappings
  keymaps.setup_command_mappings()
end

return M
