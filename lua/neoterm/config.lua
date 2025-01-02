local ui = require 'neoterm.ui'

local M = {}

-- Default configuration
M.defaults = {
  key_prefix = 'n',
  commands = {
    -- Virtual Environment Commands
    venv_activate = {
      cmd = function()
        local venv_path = require('neoterm.venv').get_venv_path()
        if not venv_path then
          vim.notify('No virtual environment found', vim.log.levels.ERROR)
          return
        end

        return {
          init = vim.o.shell,
          post_cmd = string.format('pushd %s && source bin/activate && popd', venv_path),
        }
      end,
      desc = 'Activate virtual environment',
      keys = 'va',
      group = 'v',
    },
    venv_select = {
      cmd = function()
        return {
          cmd = function()
            require('neoterm.venv').select_venv()
          end,
          module = 'neoterm.venv',
          func = 'select_venv',
        }
      end,
      desc = 'Select virtual environment path',
      keys = 'vs',
      group = 'v',
    },
    venv_show = {
      cmd = function()
        return {
          cmd = function()
            require('neoterm.venv').get_venv_path()
          end,
          module = 'neoterm.venv',
          func = 'get_venv_path',
        }
      end,
      desc = 'Show current virtual environment',
      keys = 'vw',
      group = 'v',
    },
    -- User commands until ui finished
    -- Bash alias group
    ebal = {
      cmd = 'ebal',
      desc = 'Edit bash alias',
      keys = 'ba',
      group = 'a',
    },
    ebrc = {
      cmd = 'ebrc',
      desc = 'Edit bash rc',
      keys = 'br',
      group = 'b',
    },
    -- Django management commands
    run_server = {
      cmd = function()
        local venv_path = require('neoterm.venv').get_venv_path()
        if not venv_path then
          vim.notify('No virtual environment found', vim.log.levels.ERROR)
          return
        end

        return {
          init = vim.o.shell,
          post_cmd = string.format('pushd %s && source bin/activate && popd && ./manage.py runserver', venv_path),
        }
      end,
      desc = 'Run Development Server',
      keys = 'dr',
      group = 'd',
    },

    start_tailwind = {
      cmd = function()
        local venv_path = require('neoterm.venv').get_venv_path()
        if not venv_path then
          vim.notify('No virtual environment found', vim.log.levels.ERROR)
          return
        end

        return {
          init = vim.o.shell,
          post_cmd = string.format('pushd %s && source bin/activate && popd && ./manage.py tailwind start', venv_path),
        }
      end,
      desc = 'Start Django Tailwind',
      keys = 'dt',
      group = 'd',
    },
    shell_plus = {
      cmd = function()
        local venv_path = require('neoterm.venv').get_venv_path()
        if not venv_path then
          vim.notify('No virtual environment found', vim.log.levels.ERROR)
          return
        end

        return {
          init = vim.o.shell,
          post_cmd = string.format('pushd %s && source bin/activate && popd && ./manage.py shell_plus', venv_path),
        }
      end,
      desc = 'Run Shell Plus cli',
      keys = 'ds',
      group = 'd',
    },
    diff_settings = {
      cmd = function()
        local venv_path = require('neoterm.venv').get_venv_path()
        if not venv_path then
          vim.notify('No virtual environment found', vim.log.levels.ERROR)
          return
        end

        return {
          init = vim.o.shell,
          post_cmd = string.format('pushd %s && source bin/activate && popd && ./manage.py diffsettings', venv_path),
        }
      end,
      desc = 'Diff Settings',
      keys = 'dd',
      group = 'd',
    },
    collect_static = {
      cmd = function()
        local venv_path = require('neoterm.venv').get_venv_path()
        if not venv_path then
          vim.notify('No virtual environment found', vim.log.levels.ERROR)
          return
        end

        return {
          init = vim.o.shell,
          post_cmd = string.format('pushd %s && source bin/activate && popd && ./manage.py collectstatic', venv_path),
        }
      end,
      desc = 'Collect Static',
      keys = 'dc',
      group = 'd',
    },
  },
  groups = {
    v = { name = 'Virtual environment' },
    -- User groups until ui finished
    b = { name = 'Bash aliases' },
    d = { name = 'Django Management Commands' },
  },
}

-- Current configuration
M.options = {}

-- Validation functions
local function validate_command(command)
  -- Basic structure checks
  if type(command) ~= 'table' then
    return false, 'Command must be a table'
  end

  -- Required fields
  if not command.desc or type(command.desc) ~= 'string' then
    return false, 'Command must have a string description'
  end
  if not command.keys or type(command.keys) ~= 'string' then
    return false, 'Command must have a string keys field'
  end
  if not command.group or type(command.group) ~= 'string' then
    return false, 'Command must have a string group field'
  end

  -- Command field validation
  if not command.cmd then
    return false, 'Command must have a cmd field'
  end

  -- If cmd is a table (serialized form), validate its structure
  if type(command.cmd) == 'table' then
    if command.cmd._type == 'shell_command' then
      if type(command.cmd.value) ~= 'table' then
        return false, 'Shell command value must be a table'
      end
      if not command.cmd.value.init then
        return false, 'Shell command must have an init field'
      end
      if not command.cmd.value.post_cmd or type(command.cmd.value.post_cmd) ~= 'string' then
        return false, 'Shell command must have a string post_cmd'
      end
    end
    -- If cmd is a function, we can't validate its return value until execution
  elseif type(command.cmd) ~= 'function' and type(command.cmd) ~= 'string' then
    return false, 'Command cmd must be a string, function, or valid command table'
  end

  return true, nil
end

local function validate_config(config)
  if type(config) ~= 'table' then
    return false, 'Config must be a table'
  end

  -- Validate commands
  if config.commands then
    if type(config.commands) ~= 'table' then
      return false, 'Commands must be a table'
    end
    for name, command in pairs(config.commands) do
      local valid, err = validate_command(command)
      if not valid then
        return false, string.format('Invalid command %s: %s', name, err)
      end
    end
  end

  -- Validate groups
  if config.groups then
    if type(config.groups) ~= 'table' then
      return false, 'Groups must be a table'
    end
    for name, group in pairs(config.groups) do
      if type(group) ~= 'table' or not group.name or type(group.name) ~= 'string' then
        return false, string.format('Invalid group %s: must have a string name', name)
      end
    end
  end

  return true, nil
end
-- Load config from file
local function load_config()
  local config_path = vim.fn.stdpath 'config' .. '/neoterm.json'
  local f = io.open(config_path, 'r')

  -- Return nil if no config file exists
  if not f then
    return nil
  end

  local content = f:read '*all'
  f:close()

  local ok, config = pcall(vim.json.decode, content)
  if not ok then
    vim.schedule(function()
      vim.notify('Invalid JSON in config file', vim.log.levels.WARN)
    end)
    return nil
  end

  -- Validate loaded config
  local valid, err = validate_config(config)
  if not valid then
    vim.schedule(function()
      vim.notify('Invalid config file: ' .. err, vim.log.levels.WARN)
    end)
    return nil
  end

  -- Reconstruct commands
  if config.commands then
    for name, command in pairs(config.commands) do
      -- Check if it's a table command
      if type(command.cmd) == 'table' then
        -- Shell command case (init and post_cmd)
        if command.cmd.init and type(command.cmd.post_cmd) == 'string' then
          local cmd_value = command.cmd
          command.cmd = function()
            return cmd_value
          end
        -- UI/function command case
        elseif command.cmd.module and command.cmd.func then
          command.cmd = function()
            return {
              cmd = function()
                require(command.cmd.module)[command.cmd.func]()
              end,
              module = command.cmd.module,
              func = command.cmd.func,
            }
          end
        end
      end
    end
  end

  return config
end

-- Save config to file
local function save_config(config)
  -- Validate before saving
  local valid, err = validate_config(config)
  if not valid then
    vim.schedule(function()
      vim.notify('Invalid config: ' .. err, vim.log.levels.ERROR)
    end)
    return false
  end

  -- Create a copy for saving
  local save_copy = vim.deepcopy(config)

  -- Process commands before saving
  if save_copy.commands then
    for name, command in pairs(save_copy.commands) do
      if type(command.cmd) == 'function' then
        local cmd_result = command.cmd()

        -- Shell command case (init and post_cmd)
        if type(cmd_result) == 'table' and cmd_result.init and type(cmd_result.post_cmd) == 'string' then
          command.cmd = cmd_result
        -- UI/function command case
        elseif type(cmd_result) == 'table' and type(cmd_result.cmd) == 'function' then
          -- Store module and function info if provided
          if cmd_result.module and cmd_result.func then
            command.cmd = {
              module = cmd_result.module,
              func = cmd_result.func,
            }
          else
            vim.notify('Function command missing module/func info: ' .. name, vim.log.levels.WARN)
            command.cmd = nil
          end
        else
          command.cmd = nil
        end
      end
    end
  end

  local config_path = vim.fn.stdpath 'config' .. '/neoterm.json'
  local f = io.open(config_path, 'w')
  if f then
    local success = pcall(function()
      f:write(vim.json.encode(save_copy))
      f:close()
    end)
    if success then
      -- Update options with the new config
      M.options = vim.deepcopy(save_copy)
      return true
    end
  end
  return false
end

-- Update configuration with new settings
function M.update_config(new_settings)
  local current_config = load_config()

  local merged_config
  if current_config then
    -- If config exists, merge with new settings taking precedence
    merged_config = vim.tbl_deep_extend('force', current_config, new_settings)
  else
    -- If no config exists, merge defaults with new settings
    merged_config = vim.tbl_deep_extend('force', M.defaults, new_settings)
  end

  -- Validate merged result
  local valid, err = validate_config(merged_config)
  if not valid then
    vim.schedule(function()
      vim.notify('Invalid configuration update: ' .. err, vim.log.levels.ERROR)
    end)
    return false
  end

  -- Save and sync if valid
  return save_config(merged_config)
end

-- Add new command interactively
function M.add_command()
  ui.add_command(M.options, function(updated_config)
    if M.update_config(updated_config) then
      vim.schedule(function()
        vim.notify('Command added and configuration synced', vim.log.levels.INFO)
      end)
    end
  end)
end

-- Initialize configuration
function M.setup(opts)
  -- tet
  -- print('Config setup called from:', debug.traceback())
  -- Set up venv module first if it exists in opts
  if opts and opts.venv then
    require('neoterm.venv').setup(opts.venv)
  end

  M.options = load_config()
  if M.options then
    return
  end

  -- No existing config, set up initial configuration
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
  save_config(M.options)
end

return M
