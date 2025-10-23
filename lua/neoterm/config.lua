local M = {}

-- Default configuration
M.defaults = {
  key_prefix = 'n',
  venv = {
    strategy = 'auto', -- "auto" | "venv-only" | "mise-only"
    project_root_markers = {
      'manage.py',
      '.git',
      'pyproject.toml',
      'setup.py',
    },
    venv_names = { 'venv', '.venv', 'env', '.env', 'virtualenv' },
    mise_check = 'warn_once', -- "warn_once" | "warn_always" | "fail" | "silent"
    suppress_warnings = true,
    auto_cd_to_root = true,
  },
  commands = {
    -- Virtual Environment Commands
    venv_activate = {
      cmd = function()
        local venv_path, project_root, env_type = require('neoterm.venv').ensure_valid_environment()
        if not env_type then
          return
        end
        if env_type == 'mise' then
          -- For mise: cd to project root and start a new shell there
          return {
            init = vim.o.shell,
            post_cmd = string.format('cd %s && exec $SHELL', project_root),
          }
        else
          -- Traditional venv: cd to root and activate
          return {
            init = vim.o.shell,
            post_cmd = string.format('cd %s && source %s/bin/activate', project_root, venv_path),
          }
        end
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
            require('neoterm.venv').show_venv_info()
          end,
          module = 'neoterm.venv',
          func = 'show_venv_info',
        }
      end,
      desc = 'Show current virtual environment',
      keys = 'vw',
      group = 'v',
    },
    -- Bash commands
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
        local venv_path, project_root, env_type = require('neoterm.venv').ensure_valid_environment()
        if not env_type then
          return
        end
        local base_cmd = string.format('cd %s && ./manage.py runserver', project_root)
        if env_type == 'mise' then
          return {
            init = vim.o.shell,
            post_cmd = base_cmd,
          }
        else
          return {
            init = vim.o.shell,
            post_cmd = string.format('source %s/bin/activate && %s', venv_path, base_cmd),
          }
        end
      end,
      desc = 'Run Development Server',
      keys = 'dr',
      group = 'd',
    },
    start_tailwind = {
      cmd = function()
        local venv_path, project_root, env_type = require('neoterm.venv').ensure_valid_environment()
        if not env_type then
          return
        end
        local base_cmd = string.format('cd %s && ./manage.py tailwind start', project_root)
        if env_type == 'mise' then
          return {
            init = vim.o.shell,
            post_cmd = base_cmd,
          }
        else
          return {
            init = vim.o.shell,
            post_cmd = string.format('source %s/bin/activate && %s', venv_path, base_cmd),
          }
        end
      end,
      desc = 'Start Django Tailwind',
      keys = 'dt',
      group = 'd',
    },
    shell_plus = {
      cmd = function()
        local venv_path, project_root, env_type = require('neoterm.venv').ensure_valid_environment()
        if not env_type then
          return
        end
        local base_cmd = string.format('cd %s && ./manage.py shell_plus', project_root)
        if env_type == 'mise' then
          return {
            init = vim.o.shell,
            post_cmd = base_cmd,
          }
        else
          return {
            init = vim.o.shell,
            post_cmd = string.format('source %s/bin/activate && %s', venv_path, base_cmd),
          }
        end
      end,
      desc = 'Run Shell Plus cli',
      keys = 'ds',
      group = 'd',
    },
    diff_settings = {
      cmd = function()
        local venv_path, project_root, env_type = require('neoterm.venv').ensure_valid_environment()
        if not env_type then
          return
        end
        local base_cmd = string.format('cd %s && ./manage.py diffsettings', project_root)
        if env_type == 'mise' then
          return {
            init = vim.o.shell,
            post_cmd = base_cmd,
          }
        else
          return {
            init = vim.o.shell,
            post_cmd = string.format('source %s/bin/activate && %s', venv_path, base_cmd),
          }
        end
      end,
      desc = 'Diff Settings',
      keys = 'dd',
      group = 'd',
    },
    collect_static = {
      cmd = function()
        local venv_path, project_root, env_type = require('neoterm.venv').ensure_valid_environment()
        if not env_type then
          return
        end
        local base_cmd = string.format('cd %s && ./manage.py collectstatic', project_root)
        if env_type == 'mise' then
          return {
            init = vim.o.shell,
            post_cmd = base_cmd,
          }
        else
          return {
            init = vim.o.shell,
            post_cmd = string.format('source %s/bin/activate && %s', venv_path, base_cmd),
          }
        end
      end,
      desc = 'Collect Static',
      keys = 'dc',
      group = 'd',
    },
  },
  groups = {
    v = { name = 'Virtual environment' },
    b = { name = 'Bash aliases' },
    d = { name = 'Django Management Commands' },
  },
}

-- Current configuration
M.options = {}

-- Initialize configuration
function M.setup(opts)
  -- Start with defaults and merge user options
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})

  -- Set up venv module with venv-specific config
  if M.options.venv then
    require('neoterm.venv').setup(M.options.venv)
  end
end

return M
