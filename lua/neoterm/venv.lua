-- lua/neoterm/venv.lua
local utils = require 'neoterm.utils'
local M = {}

-- Session storage
M.session_venv = nil

-- Find nearest virtualenv
local function find_nearest_venv()
  local venv_names = { 'venv', '.venv', 'env', '.env', 'virtualenv' }
  local current = vim.fn.getcwd()

  while current ~= '/' do
    for _, name in ipairs(venv_names) do
      local path = current .. '/' .. name
      if vim.fn.isdirectory(path) == 1 and vim.fn.filereadable(path .. '/bin/activate') == 1 then
        return path
      end
    end
    current = vim.fn.fnamemodify(current, ':h')
  end
  return nil
end

function M.get_venv_path()
  -- debug
  -- vim.notify(string.format('GETTING VENV PATH %s/', M.session_venv), vim.log.levels.INFO)
  if M.session_venv then
    if vim.fn.isdirectory(M.session_venv) == 1 and vim.fn.filereadable(M.session_venv .. '/bin/activate') == 1 then
      return M.session_venv
    end
    M.session_venv = nil
  end
  return find_nearest_venv()
end

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

function M.setup(opts)
  if opts and opts.initial_venv then
    M.set_venv_path(opts.initial_venv)
  end
end

return M
