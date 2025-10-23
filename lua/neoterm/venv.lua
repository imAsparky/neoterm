-- lua/neoterm/venv.lua
local utils = require 'neoterm.utils'
local M = {}

-- Session storage
M.session_venv = nil

-- Configuration
M.config = {
  strategy = 'auto',
  project_root_markers = {
    'manage.py',
    '.git',
    'pyproject.toml',
    'setup.py',
  },
  venv_names = { 'venv', '.venv', 'env', '.env', 'virtualenv' },
  mise_check = 'warn_once',
  suppress_warnings = true,
  auto_cd_to_root = true,
}

-- mise validation cache
local mise_check_done = false
local mise_available = false

-- Check if mise is available in PATH
local function check_mise_available()
  if mise_check_done then
    return mise_available
  end

  mise_check_done = true
  local handle = io.popen 'command -v mise 2>/dev/null'
  if not handle then
    return false
  end
  local result = handle:read '*a'
  handle:close()
  mise_available = result and result:match '%S' ~= nil
  return mise_available
end

-- Validate mise availability and notify based on config
local function validate_mise()
  local check_mode = M.config.mise_check or 'warn_once'

  if check_mode == 'silent' then
    return true
  end

  local available = check_mise_available()

  if not available then
    if check_mode == 'fail' then
      error 'mise.toml detected but mise not found in PATH'
    elseif check_mode == 'warn_once' and not M.config.suppress_warnings then
      vim.schedule(function()
        vim.notify('mise.toml detected but mise not found in PATH.\n' .. 'Install: https://mise.jdx.dev/getting-started.html', vim.log.levels.WARN)
      end)
    elseif check_mode == 'warn_always' then
      vim.schedule(function()
        vim.notify('mise not available in PATH', vim.log.levels.WARN)
      end)
    end
    return false
  end

  return true
end

-- Find project root by walking up from current directory
local function find_project_root()
  local current = vim.fn.getcwd()
  local markers = M.config.project_root_markers or {
    'manage.py',
    '.git',
    'pyproject.toml',
    'setup.py',
  }

  while current ~= '/' do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(current .. '/' .. marker) == 1 or vim.fn.isdirectory(current .. '/' .. marker) == 1 then
        return current
      end
    end
    current = vim.fn.fnamemodify(current, ':h')
  end

  return nil
end

-- Find environment (mise or venv) starting from project root
local function find_environment(project_root)
  if not project_root then
    return nil, nil, 'none'
  end

  local strategy = M.config.strategy

  -- FIRST: Check project root itself
  local has_mise = false
  local has_venv = false
  local found_venv_path = nil
  local found_venv_name = nil

  -- Check for mise
  if
    vim.fn.filereadable(project_root .. '/mise.toml') == 1
    or vim.fn.filereadable(project_root .. '/.mise.toml') == 1
    or vim.fn.filereadable(project_root .. '/.tool-versions') == 1
  then
    has_mise = true
  end

  -- Check for venv
  for _, name in ipairs(M.config.venv_names) do
    local venv_path = project_root .. '/' .. name
    if vim.fn.isdirectory(venv_path) == 1 and vim.fn.filereadable(venv_path .. '/bin/activate') == 1 then
      has_venv = true
      found_venv_path = venv_path
      found_venv_name = name
      break
    end
  end

  -- CONFLICT DETECTION: Both exist in project root
  if has_mise and has_venv then
    if strategy == 'auto' then
      -- Force user to choose
      vim.schedule(function()
        vim.notify(
          string.format(
            'ERROR: Both mise.toml and %s/ detected in %s\n\n'
              .. 'This is ambiguous. Please set an explicit strategy:\n'
              .. '  venv = { strategy = "mise-only" }  -- Use mise\n'
              .. '  venv = { strategy = "venv-only" }  -- Use venv\n\n'
              .. 'Or remove the unused environment manager.',
            found_venv_name,
            project_root
          ),
          vim.log.levels.ERROR
        )
      end)
      return nil, project_root, 'conflict'
    elseif strategy == 'mise-only' then
      -- User explicitly chose mise
      validate_mise()
      return project_root, project_root, 'mise'
    elseif strategy == 'venv-only' then
      -- User explicitly chose venv
      return found_venv_path, project_root, 'venv'
    end
  end

  -- Single environment found - use it based on strategy
  if has_mise and strategy ~= 'venv-only' then
    validate_mise()
    return project_root, project_root, 'mise'
  end

  if has_venv and strategy ~= 'mise-only' then
    return found_venv_path, project_root, 'venv'
  end

  -- THEN: Walk up parent directories
  local current = vim.fn.fnamemodify(project_root, ':h')
  while current ~= '/' do
    -- Check mise in parent (unless venv-only)
    if strategy ~= 'venv-only' then
      if
        vim.fn.filereadable(current .. '/mise.toml') == 1
        or vim.fn.filereadable(current .. '/.mise.toml') == 1
        or vim.fn.filereadable(current .. '/.tool-versions') == 1
      then
        validate_mise()
        return current, project_root, 'mise'
      end
    end

    -- Check venv in parent (unless mise-only)
    if strategy ~= 'mise-only' then
      for _, name in ipairs(M.config.venv_names) do
        local venv_path = current .. '/' .. name
        if vim.fn.isdirectory(venv_path) == 1 and vim.fn.filereadable(venv_path .. '/bin/activate') == 1 then
          return venv_path, project_root, 'venv'
        end
      end
    end

    current = vim.fn.fnamemodify(current, ':h')
  end

  return nil, project_root, 'none'
end

-- Get virtual environment path
-- Returns: env_root, project_root, env_type
-- env_type can be: 'mise', 'venv', 'none', 'conflict'
function M.get_venv_path()
  -- Return session venv if explicitly set
  if M.session_venv then
    if vim.fn.isdirectory(M.session_venv) == 1 then
      local root = find_project_root()
      return M.session_venv, root or M.session_venv, 'venv'
    end
    M.session_venv = nil
  end

  local project_root = find_project_root()
  return find_environment(project_root)
end

-- Helper function to ensure valid environment before running commands
function M.ensure_valid_environment()
  local venv_path, project_root, env_type = M.get_venv_path()

  if env_type == 'none' then
    if not M.config.suppress_warnings then
      vim.notify('No virtual environment or mise config found', vim.log.levels.ERROR)
    end
    return nil
  end

  if env_type == 'conflict' then
    vim.notify('Cannot execute: conflicting environments detected.\n' .. 'Set explicit strategy in config.', vim.log.levels.ERROR)
    return nil
  end

  return venv_path, project_root, env_type
end

-- Set virtual environment path manually
function M.set_venv_path(path)
  -- Early validation
  if not path or path == '' then
    vim.notify('Virtual environment path cannot be empty', vim.log.levels.ERROR)
    return false
  end

  -- Path length check (validation)
  if #path > 1024 then
    vim.notify('Path exceeds maximum length', vim.log.levels.ERROR)
    return false
  end

  -- Normalize and expand the path
  local expanded_path = utils.normalize_path(vim.fn.expand(path))

  -- Absolute path check (validation)
  if not vim.fn.fnamemodify(expanded_path, ':p') then
    vim.notify('Failed to resolve absolute path', vim.log.levels.ERROR)
    return false
  end
  if vim.fn.isdirectory(expanded_path) ~= 1 then
    vim.notify('Virtual environment directory not found: ' .. expanded_path, vim.log.levels.ERROR)
    return false
  end

  if vim.fn.filereadable(expanded_path .. '/bin/activate') ~= 1 then
    vim.notify('Invalid virtual environment (no activate script found): ' .. expanded_path, vim.log.levels.ERROR)
    return false
  end

  M.session_venv = expanded_path
  vim.notify('Virtual environment set to: ' .. expanded_path, vim.log.levels.INFO)
  return true
end

-- Interactive venv selection
function M.select_venv()
  vim.ui.input({
    prompt = 'Enter virtual environment path: ',
    default = M.session_venv or '',
    completion = 'dir',
  }, function(input)
    if input then
      M.set_venv_path(input)
    end
  end)
end

-- Show current environment info
function M.show_venv_info()
  local venv_path, project_root, env_type = M.get_venv_path()

  if env_type == 'none' then
    vim.notify('No virtual environment found', vim.log.levels.WARN)
  elseif env_type == 'conflict' then
    vim.notify('Environment conflict detected - see error messages', vim.log.levels.ERROR)
  elseif env_type == 'mise' then
    vim.notify(string.format('mise-managed project\nProject root: %s\nEnvironment root: %s', project_root, venv_path), vim.log.levels.INFO)
  else
    vim.notify(string.format('venv: %s\nProject root: %s', venv_path, project_root), vim.log.levels.INFO)
  end
end

-- Setup configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  if M.config.initial_venv then
    M.set_venv_path(M.config.initial_venv)
  end
end

return M
