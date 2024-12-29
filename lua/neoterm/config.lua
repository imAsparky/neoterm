-- lua/neoterm/config.lua
local M = {}

-- Default configuration
M.defaults = {
  venv_name = 'venv',
  key_prefix = 'n',
  commands = {
    -- Default commands can go here
  },
  groups = {
    -- Default groups can go here
  },
}

-- Current configuration
M.options = {}

-- Define the schema for validation
local schema = {
  venv_name = {
    type = 'string',
    required = true,
  },
  commands = {
    type = 'table',
    required = false,
    validate = function(commands)
      for name, command in pairs(commands) do
        if type(command) ~= 'table' then
          return false, string.format("Command '%s' must be a table", name)
        end

        if not command.cmd then
          return false, string.format("Command '%s' missing required field 'cmd'", name)
        end
        if not command.desc then
          return false, string.format("Command '%s' missing required field 'desc'", name)
        end

        if type(command.cmd) ~= 'string' and type(command.cmd) ~= 'function' then
          return false, string.format("Command '%s' field 'cmd' must be string or function", name)
        end
        if type(command.desc) ~= 'string' then
          return false, string.format("Command '%s' field 'desc' must be string", name)
        end
        if command.keys and type(command.keys) ~= 'string' then
          return false, string.format("Command '%s' field 'keys' must be string", name)
        end
        if command.group and type(command.group) ~= 'string' then
          return false, string.format("Command '%s' field 'group' must be string", name)
        end
      end
      return true
    end,
  },
  groups = {
    type = 'table',
    required = false,
    validate = function(groups)
      for name, group in pairs(groups) do
        if type(group) ~= 'table' then
          return false, string.format("Group '%s' must be a table", name)
        end

        if not group.name then
          return false, string.format("Group '%s' missing required field 'name'", name)
        end

        if type(group.name) ~= 'string' then
          return false, string.format("Group '%s' field 'name' must be string", name)
        end
      end
      return true
    end,
  },
}

-- Validate the config against our schema
local function validate_config(config)
  if type(config) ~= 'table' then
    return false, 'Config must be a table'
  end

  -- Check required fields and types
  for field, validator in pairs(schema) do
    if validator.required and config[field] == nil then
      return false, string.format("Missing required field '%s'", field)
    end

    if config[field] ~= nil then
      if type(config[field]) ~= validator.type then
        return false, string.format("Field '%s' must be a %s", field, validator.type)
      end

      if validator.validate then
        local ok, err = validator.validate(config[field])
        if not ok then
          return false, err
        end
      end
    end
  end

  return true
end

-- Load or create config file
local function load_config()
  local config_path = vim.fn.stdpath 'config' .. '/neoterm.json'
  local f = io.open(config_path, 'r')
  if f then
    local content = f:read '*all'
    f:close()
    local ok, config = pcall(vim.json.decode, content)
    if ok then
      -- Validate loaded config
      local valid, err = validate_config(config)
      if not valid then
        vim.schedule(function()
          vim.notify('Invalid config file: ' .. err, vim.log.levels.WARN)
          vim.notify('Falling back to defaults', vim.log.levels.INFO)
        end)
        return { venv_name = M.defaults.venv_name, key_prefix = M.defaults.key_prefix }
      end
      return config
    end
  end
  return { venv_name = M.defaults.venv_name, key_prefix = M.defaults.key_prefix }
end

-- Save config to file
local function save_config(config)
  -- Validate before saving
  local valid, err = validate_config(config)
  if not valid then
    vim.schedule(function()
      vim.notify('Cannot save invalid config: ' .. err, vim.log.levels.ERROR)
    end)
    return false
  end

  local config_path = vim.fn.stdpath 'config' .. '/neoterm.json'
  local f = io.open(config_path, 'w')
  if f then
    f:write(vim.json.encode(config))
    f:close()
    return true
  end
  return false
end

-- UI notification logic
local function notify_venv_update(name, is_default)
  local message = is_default and 'No input provided - using default virtual environment name: ' .. name
    or 'Virtual environment name set to: ' .. name .. ' (saved for future sessions)'
  vim.schedule(function()
    vim.notify(message, vim.log.levels.INFO)
  end)
end

-- Update venv name
function M.set_venv(name)
  local config = {
    venv_name = name,
    commands = M.options.commands,
    groups = M.options.groups,
  }

  if save_config(config) then
    M.options.venv_name = name
    vim.cmd 'echo ""' -- Clear command line
    notify_venv_update(name, false)
  end
end

-- Configure venv interactively
function M.configure_venv()
  local current_name = M.options.venv_name
  -- Get user input
  local input = vim.fn.input('Enter venv name: ', current_name, 'file')
  vim.cmd 'echo ""' -- Clear command line immediately after input
  -- Handle the input
  if input and input ~= '' then
    M.set_venv(input)
  else
    M.set_venv(M.defaults.venv_name)
    notify_venv_update(M.defaults.venv_name, true)
  end
end

-- Initialize configuration
function M.setup(opts)
  -- Merge defaults with saved config and user opts
  local saved_config = load_config()
  local merged_config = vim.tbl_deep_extend('force', M.defaults, saved_config or {}, opts or {})

  -- Validate merged config
  local valid, err = validate_config(merged_config)
  if not valid then
    vim.schedule(function()
      vim.notify('Invalid configuration: ' .. err, vim.log.levels.ERROR)
      vim.notify('Falling back to defaults', vim.log.levels.INFO)
    end)
    M.options = vim.deepcopy(M.defaults)
    return
  end

  M.options = merged_config
end

if vim.env.DEVELOPING then
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*/neoterm/**/*.lua',
    callback = function()
      -- Unload all loaded modules that match your plugin's pattern
      for module, _ in pairs(package.loaded) do
        if module:match '^neoterm' then
          package.loaded[module] = nil
        end
      end
      -- Reload setup
      require('neoterm').setup()
    end,
  })
end

return M
