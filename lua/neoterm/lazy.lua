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
    venv_name = 'venv', -- default virtual environment folder name
    key_prefix = 'n', -- default which-key menu prefix
  },
}
