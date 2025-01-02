-- lua/neoterm/ui_commands.lua
-- NOTE: May be redundant/or needs more work, testing some options for adding ui commands
local M = {}

function M.configure_command()
  vim.notify('Configure command test', vim.log.levels.INFO)
end

function M.configure_group()
  vim.notify('Configure group test', vim.log.levels.INFO)
end

function M.setup(command_registry)
  vim.notify('UI COMMANDS SET UP', vim.log.levels.ERROR)
  -- Define UI commands using our standard format
  local ui_commands = {
    configure_command = {
      cmd = M.configure_command,
      desc = 'Add a new command',
      keys = 'cc',
      group = 'c',
    },
    configure_group = {
      cmd = M.configure_group,
      desc = 'Add a new group',
      keys = 'cg',
      group = 'c',
    },
    groups = {
      c = { name = 'UI commands' },
    },
  }

  -- Process each command through our existing registry
  for name, command in pairs(ui_commands) do
    command_registry.process_config { commands = { [name] = command } }
  end
end

return M
