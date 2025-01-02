local M = {}

-- Schema definition for configuration validation
M.schema = {
  commands = {
    type = 'table',
    required = false,
    validate = function(commands)
      for name, command in pairs(commands) do
        if type(command) ~= 'table' then
          return false, string.format("Command '%s' must be a table", name)
        end

        -- cmd can be nil when saved to file
        if command.cmd and type(command.cmd) ~= 'string' and type(command.cmd) ~= 'function' then
          return false, string.format("Command '%s' field 'cmd' must be string or function when present", name)
        end
        if not command.desc then
          return false, string.format("Command '%s' missing required field 'desc'", name)
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

-- Validate configuration against schema
function M.validate_config(config)
  if type(config) ~= 'table' then
    return false, 'Config must be a table'
  end

  -- Check required fields and types
  for field, validator in pairs(M.schema) do
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

-- UI notification helper
local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO)
  end)
end

-- Add command UI
function M.add_command(config, on_success)
  local function prompt_field(prompt, default)
    local input = vim.fn.input(prompt, default or '')
    vim.cmd 'echo ""'
    return input
  end

  local name = prompt_field 'Command name: '
  if not name or name == '' then
    notify('Command name cannot be empty', vim.log.levels.WARN)
    return
  end

  local desc = prompt_field 'Command description: '
  if not desc or desc == '' then
    notify('Command description cannot be empty', vim.log.levels.WARN)
    return
  end

  local keys = prompt_field 'Command keys (optional): '
  local group = prompt_field 'Command group (optional): '

  local new_command = {
    desc = desc,
    cmd = '', -- This will need to be set up separately
    keys = keys ~= '' and keys or nil,
    group = group ~= '' and group or nil,
  }

  local updated_config = vim.deepcopy(config)
  updated_config.commands = updated_config.commands or {}
  updated_config.commands[name] = new_command

  local valid, err = M.validate_config(updated_config)
  if not valid then
    notify('Invalid command configuration: ' .. err, vim.log.levels.ERROR)
    return
  end

  on_success(updated_config)
  notify('Command "' .. name .. '" added successfully', vim.log.levels.INFO)
end

return M
