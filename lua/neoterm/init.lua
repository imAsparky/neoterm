-- lua/neoterm/init.lua
local M = {}

function M.setup(opts)
  -- Check for which-key dependency
  local has_which_key, _ = pcall(require, 'which-key')
  if not has_which_key then
    vim.notify(
      [[
Neoterm: which-key.nvim is required but not found.

Please install which-key.nvim first:
https://github.com/folke/which-key.nvim
]],
      vim.log.levels.ERROR
    )
    return
  end

  local config = require 'neoterm.config'
  local command_registry = require 'neoterm.command_registry'
  local ui_commands = require 'neoterm.ui_commands'

  config.setup()
  command_registry.setup()
  ui_commands.setup(command_registry)

  -- -- Initialize configuration
  -- require('neoterm.config').setup(opts)
  --
  -- -- Initialize command registry and keymaps
  -- require('neoterm.command_registry').setup()
  --
  -- -- Initialise UI components
  -- require('neoterm.ui_commands').setup(command_registry)
end

return M

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
