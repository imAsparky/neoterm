local M = {}
local health = vim.health or require 'health'
local config = require 'neoterm.config'

-- Function to get the actual leader key setting
local function get_leader_display()
  local leader = vim.g.mapleader
  if leader == ' ' then
    return '<Space>'
  elseif type(leader) == 'string' then
    return '<' .. leader .. '>'
  else
    return '<Leader>' -- default if not set
  end
end

-- Check if there are any mappings starting with leader + prefix
local function check_prefix_mappings(prefix)
  local leader = get_leader_display()
  local mapping = leader .. prefix

  -- Get all mappings and filter for ones starting with our prefix
  local all_maps = vim.fn.execute 'verbose map'
  local existing_mappings = {}

  -- Split into lines and process each mapping
  for line in vim.gsplit(all_maps, '\n') do
    -- Look for lines that start with a mode character (n, v, x, s, o, i, l, c, t)
    if line:match '^[nvxsoilct]%s+' then
      -- If this mapping starts with our prefix
      if line:match(mapping) then
        table.insert(existing_mappings, line)
      end
    end
  end

  return #existing_mappings > 0, table.concat(existing_mappings, '\n')
end

-- Comprehensive version check function
local function check_version()
  local version = vim.version()
  local required = { 0, 10, 0 }
  -- First check actual version numbers
  local version_ok = version.major > required[1] or (version.major == required[1] and version.minor >= required[2])
  if version_ok then
    health.ok(string.format('Neovim version %d.%d.%d meets requirements', version.major, version.minor, version.patch))
  else
    health.error(
      string.format(
        'Neovim version %d.%d.%d does not meet minimum requirement of %d.%d.%d',
        version.major,
        version.minor,
        version.patch,
        required[1],
        required[2],
        required[3]
      )
    )
  end
end

-- Check Django installation
local function check_django(project_root, venv_path, env_type)
  -- Check if manage.py exists
  if vim.fn.filereadable(project_root .. '/manage.py') ~= 1 then
    return nil -- Not a Django project
  end

  health.info '\nDjango Detection:'
  health.info(string.format('  manage.py found in: %s', project_root))

  -- Check if Django is installed
  local django_check_cmd
  if env_type == 'mise' then
    django_check_cmd = string.format('cd %s && python -c "import django; print(django.get_version())" 2>/dev/null', project_root)
  else
    django_check_cmd =
      string.format('source %s/bin/activate && cd %s && python -c "import django; print(django.get_version())" 2>/dev/null', venv_path, project_root)
  end

  local handle = io.popen(django_check_cmd)
  if handle then
    local django_version = handle:read '*l'
    handle:close()
    if django_version and django_version ~= '' then
      health.ok(string.format('  Django %s installed', django_version))
      return true
    else
      health.warn '  Django not installed (Django commands will not work)'
      health.info '    Install Django: pip install django'
      return false
    end
  end

  health.error '  Could not check Django installation'
  return false
end

-- Get Python version
local function get_python_version(project_root, venv_path, env_type)
  local python_cmd

  if env_type == 'mise' then
    python_cmd = string.format('cd %s && python --version 2>&1', project_root)
  else
    python_cmd = string.format('%s/bin/python --version 2>&1', venv_path)
  end

  local handle = io.popen(python_cmd)
  if handle then
    local version = handle:read '*l'
    handle:close()
    if version and version ~= '' then
      return version
    end
  end

  return nil
end

function M.check()
  health.start 'neoterm'

  -- Check version requirements
  check_version()

  -- Check leader key setting
  local leader_display = get_leader_display()
  health.info(string.format('Leader key: %s', leader_display))

  -- Check for which-key.nvim
  local has_which_key = pcall(require, 'which-key')
  if has_which_key then
    health.ok 'which-key.nvim is installed'
  else
    health.error 'which-key.nvim is required but not found'
    health.info '  Install: https://github.com/folke/which-key.nvim'
  end

  -- Check terminal capabilities
  if vim.fn.exists '*termopen' == 1 and vim.fn.exists '*jobstart' == 1 then
    health.ok 'Terminal support available'
  else
    health.error 'Terminal support not available'
  end

  -- Environment Detection
  health.info '\nEnvironment Detection:'
  health.info(string.format('  Working directory: %s', vim.fn.getcwd()))

  local venv_path, project_root, env_type = require('neoterm.venv').get_venv_path()

  if env_type == 'none' then
    health.warn '  No environment detected'
    health.info(string.format('    Looking for project markers: %s', table.concat(config.options.venv.project_root_markers, ', ')))
    health.info(string.format('    Looking for venv names: %s', table.concat(config.options.venv.venv_names, ', ')))
  elseif env_type == 'conflict' then
    health.error '  CONFLICT: Both mise.toml and venv detected'
    health.error(string.format('    Project root: %s', project_root))
    health.info '    Resolve by setting explicit strategy:'
    health.info '      venv = { strategy = "mise-only" }  -- to use mise'
    health.info '      venv = { strategy = "venv-only" }  -- to use venv'
  else
    health.ok(string.format('  Project root: %s', project_root))
    health.ok(string.format('  Environment root: %s', venv_path))
    health.ok(string.format('  Environment type: %s', env_type))

    -- Check mise availability
    if env_type == 'mise' then
      if vim.fn.executable 'mise' == 1 then
        health.ok '  mise available in PATH'
      else
        health.warn '  mise not found in PATH'
        health.info '    Shell integration may still work'
        health.info '    Install: https://mise.jdx.dev/getting-started.html'
      end
    end

    -- Get Python version
    local python_version = get_python_version(project_root, venv_path, env_type)
    if python_version then
      health.info(string.format('  %s', python_version))
    end

    -- Check Django
    check_django(project_root, venv_path, env_type)
  end

  -- Configuration display
  health.info '\nConfiguration:'

  -- Get venv module config (where the actual values are stored)
  local venv_config = require('neoterm.venv').config

  health.info(string.format('  Strategy: %s', venv_config.strategy or 'auto'))

  if venv_config.project_root_markers then
    health.info(string.format('  Project root markers: %s', table.concat(venv_config.project_root_markers, ', ')))
  end

  if venv_config.venv_names then
    health.info(string.format('  Venv directory names: %s', table.concat(venv_config.venv_names, ', ')))
  end

  if venv_config.mise_check then
    health.info(string.format('  mise validation: %s', venv_config.mise_check))
  end

  if venv_config.suppress_warnings ~= nil then
    health.info(string.format('  Suppress warnings: %s', tostring(venv_config.suppress_warnings)))
  end

  -- Check prefix mappings
  local prefix = (config.options.key_prefix or 'n'):lower()
  local has_mappings, existing_mappings = check_prefix_mappings(prefix)

  if has_mappings then
    health.info(string.format("\nExisting mappings for '%s%s':", get_leader_display(), prefix))
    for line in existing_mappings:gmatch '[^\n]+' do
      health.info('  ' .. line)
    end
  else
    health.ok(string.format("\nNo conflicting mappings found for '%s%s'", get_leader_display(), prefix))
  end
end

return M
