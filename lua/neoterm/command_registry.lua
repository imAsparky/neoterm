-- lua/neoterm/command_registry.lua
local M = {}
local config = require 'neoterm.config'
local keymaps = require 'neoterm.keymaps'
local terminal = require 'neoterm.terminal'

-- Function to process commands and groups from config
function M.process_config()
  -- Get the merged config (defaults + user config)
  local current_config = config.options

  -- Process all commands and register them with the keymap module
  if current_config.commands then
    for name, command in pairs(current_config.commands) do
      -- Register keymap
      keymaps.register_command(name, command)

      -- Create valid command name (replace underscore with camelCase)
      local cmd_name = 'Neoterm' .. name
        :gsub('_(.)', function(c)
          return c:upper()
        end)
        :gsub('^%l', string.upper)

      -- Create Vim command
      vim.api.nvim_create_user_command(cmd_name, function()
        local cmd_config = type(command.cmd) == 'function' and command.cmd() or command.cmd

        -- If it's a direct function, just execute it
        if type(cmd_config) == 'function' then
          cmd_config()
        -- If it's a table with ui_callback, execute that
        elseif type(cmd_config) == 'table' and cmd_config.ui_callback then
          cmd_config.ui_callback()
        -- Otherwise treat as terminal command
        else
          terminal.run_command(name)
        end
      end, {
        desc = command.desc,
      })
      -- vim.api.nvim_create_user_command(cmd_name, function()
      --   -- Check if it's a UI command by looking at the command structure
      --   local cmd_config = type(command.cmd) == 'function' and command.cmd() or command.cmd
      --   if type(cmd_config) == 'table' and cmd_config.ui_callback then
      --     -- Execute UI command
      --     cmd_config.ui_callback()
      --   else
      --     -- Execute terminal command
      --     terminal.run_command(name)
      --   end
      -- end, {
      --   desc = command.desc,
      -- })
    end
  end
end

-- Main setup function
function M.setup()
  -- Set up base keymaps
  keymaps.setup()
  -- Process commands from config and set up their keymaps
  M.process_config()
  -- Set up command mappings
  keymaps.setup_command_mappings()
end

return M
