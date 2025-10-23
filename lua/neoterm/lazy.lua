return {
  'imAsparky/neoterm',
  dependencies = {
    'folke/which-key.nvim', --  which-key is a required dependency
  },
  event = 'VeryLazy',
  config = function()
    require('neoterm').setup()
  end,
  opts = {
    key_prefix = 'n', -- default which-key menu prefix
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
  },
}
