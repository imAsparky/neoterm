-- lua/neoterm/init.lua
local M = {}

local function is_development_mode()
  -- Add debug print
  -- vim.notify('DEVELOPING env var: ' .. tostring(vim.env.DEVELOPING))
  return vim.env.DEVELOPING and vim.env.DEVELOPING ~= '0' and vim.env.DEVELOPING:lower() ~= 'false'
end

local function setup_development_mode()
  if not is_development_mode() then
    return
  end

  vim.notify('Neoterm: Development mode enabled - auto-reloading activated', vim.log.levels.INFO)

  -- Add debug print for pattern
  vim.notify 'Setting up BufWritePost autocmd with pattern: */neoterm/**/*.lua'
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*/neoterm/**/*.lua',
    callback = function(ev)
      vim.notify(string.format('Neoterm: Reloading due to changes in %s', ev.file), vim.log.levels.INFO)

      -- Unload all modules
      for module, _ in pairs(package.loaded) do
        if module:match '^neoterm' then
          -- TODO: Add a verbosity flag in command.
          -- vim.notify(string.format('Neoterm: Unloading module %s', module), vim.log.levels.DEBUG)
          package.loaded[module] = nil
        end
      end

      -- Force reload core modules in specific order
      vim.schedule(function()
        -- Reload the plugin
        require('neoterm').setup()
        vim.notify('Neoterm: Reload complete', vim.log.levels.INFO)
      end)
    end,
    group = vim.api.nvim_create_augroup('NeotermDevelopment', { clear = true }),
  })
end

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

  -- Initialize configuration
  require('neoterm.config').setup(opts)

  -- Initialize command registry and keymaps
  require('neoterm.command_registry').setup()

  -- Initialise UI components
  -- NOTE: this file is testing some ui command options, may be redundant.
  -- require('neoterm.ui_commands').setup(command_registry)

  -- Setup development mode after all other initializations
  setup_development_mode()
end

return M
