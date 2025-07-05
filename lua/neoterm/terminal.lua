-- lua/neoterm/terminal.lua
local M = {}
local config = require 'neoterm.config'

-- Plugin state
local state = {
  floating = {
    buf = -1, -- Buffer ID
    win = -1, -- Window ID
  },
}

-- Helper function to send commands to terminal
local function send_to_terminal(bufnr, cmd)
  local chan = vim.api.nvim_buf_get_var(bufnr, 'terminal_job_id')
  vim.api.nvim_chan_send(chan, cmd .. '\n')
end

-- Set up terminal buffer options with theme-aware color handling
local function setup_terminal(bufnr)
  -- Set buffer options
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].bufhidden = 'hide' -- Ensure the terminal is available until killed

  -- Apply background matching to current theme
  local function apply_background()
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
    if normal.bg then
      vim.api.nvim_set_hl(0, 'TerminalNormal', { bg = normal.bg, fg = normal.fg })
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value('winhl', 'Normal:TerminalNormal', { win = win })
    end
  end

  vim.schedule(apply_background)

  -- Start terminal in insert mode
  vim.cmd 'startinsert'

  -- Auto-enter insert mode when focusing terminal
  local term_group = vim.api.nvim_create_augroup('TerminalBehavior' .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = term_group,
    buffer = bufnr,
    callback = function()
      if vim.bo[bufnr].buftype == 'terminal' then
        vim.cmd 'startinsert'
        apply_background()
      end
    end,
  })

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = term_group,
    callback = function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.schedule(apply_background)
      end
    end,
  })
end

-- Get terminal colors from current theme
local function get_theme_terminal_colors()
  local colors = {}
  local found_any = false

  -- Check if the theme already set terminal colors (ideal case)
  for i = 0, 15 do
    local existing_color = vim.g['terminal_color_' .. i]
    if existing_color then
      colors[i + 1] = existing_color
      found_any = true
    end
  end

  if found_any then
    return colors
  end

  -- If theme doesn't set terminal colors, extract from highlight groups
  local function get_hl_color(hl_name, attr, fallback)
    local hl = vim.api.nvim_get_hl(0, { name = hl_name })
    if hl and hl[attr] then
      return string.format('#%06x', hl[attr])
    end
    return fallback
  end

  -- Map semantic highlight groups to ANSI colors
  return {
    get_hl_color('Comment', 'fg', '#45475a'), -- 0: black
    get_hl_color('Error', 'fg', '#f38ba8'), -- 1: red
    get_hl_color('String', 'fg', '#a6e3a1'), -- 2: green
    get_hl_color('Warning', 'fg', '#f9e2af'), -- 3: yellow
    get_hl_color('Function', 'fg', '#89b4fa'), -- 4: blue
    get_hl_color('Keyword', 'fg', '#f5c2e7'), -- 5: magenta
    get_hl_color('Special', 'fg', '#94e2d5'), -- 6: cyan
    get_hl_color('Normal', 'fg', '#bac2de'), -- 7: white
    get_hl_color('NonText', 'fg', '#585b70'), -- 8: bright black
    get_hl_color('ErrorMsg', 'fg', '#f38ba8'), -- 9: bright red
    get_hl_color('DiffAdd', 'fg', '#a6e3a1'), -- 10: bright green
    get_hl_color('WarningMsg', 'fg', '#f9e2af'), -- 11: bright yellow
    get_hl_color('Identifier', 'fg', '#89b4fa'), -- 12: bright blue
    get_hl_color('Type', 'fg', '#f5c2e7'), -- 13: bright magenta
    get_hl_color('Operator', 'fg', '#94e2d5'), -- 14: bright cyan
    get_hl_color('Normal', 'fg', '#a6adc8'), -- 15: bright white
  }
end

-- Create floating terminal window with dynamic color detection
local function create_float_term(opts)
  opts = opts or {}

  -- Set terminal colors dynamically from current theme before terminal creation
  local terminal_colors = get_theme_terminal_colors()

  for i = 0, 15 do
    local color = terminal_colors[i + 1]
    if color then
      vim.g['terminal_color_' .. i] = color
    end
  end

  -- Get editor dimensions
  local width = vim.o.columns
  local height = vim.o.lines

  -- Calculate window dimensions (80% of screen)
  local win_width = opts.width or math.floor(width * 0.8)
  local win_height = opts.height or math.floor(height * 0.8)

  -- Calculate starting position to center the window
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  -- Create or reuse buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  -- Window configuration
  local win_config = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Neoterm ',
    title_pos = 'center',
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- Set up terminal behavior if this is a new buffer
  if not vim.api.nvim_buf_is_valid(opts.buf) then
    setup_terminal(buf)
  end

  return {
    buf = buf,
    win = win,
  }
end

-- Function to run terminal command
function M.run_command(command_name)
  local cmd = config.options.commands[command_name]
  if not cmd then
    vim.notify('Unknown command: ' .. command_name, vim.log.levels.ERROR)
    return
  end

  -- Get initial command value
  local command = type(cmd.cmd) == 'function' and cmd.cmd() or cmd.cmd

  -- Handle function commands
  if type(command) == 'function' then
    command()
    return
  -- Handle module/function commands
  elseif type(command) == 'table' then
    if command.module and command.func then
      -- Execute the module function
      require(command.module)[command.func]()
      return
    elseif command.init and type(command.post_cmd) == 'string' then
      -- Handle shell commands with init/post_cmd
      if not vim.api.nvim_win_is_valid(state.floating.win) then
        state.floating = create_float_term { buf = state.floating.buf }

        vim.fn.termopen(command.init)

        -- Wait briefly for terminal to initialize
        vim.defer_fn(function()
          if command.post_cmd then
            send_to_terminal(state.floating.buf, command.post_cmd)
          end
        end, 100)

        vim.cmd 'startinsert'
      else
        vim.api.nvim_win_hide(state.floating.win)
      end
      return
    end
  -- Handle string commands (direct terminal commands)
  elseif type(command) == 'string' then
    if not vim.api.nvim_win_is_valid(state.floating.win) then
      state.floating = create_float_term { buf = state.floating.buf }

      vim.fn.termopen(command)

      vim.cmd 'startinsert'
    else
      vim.api.nvim_win_hide(state.floating.win)
    end
    return
  end

  vim.notify(string.format('Invalid command type: %s', type(command)), vim.log.levels.ERROR)
end

-- Toggle terminal window
function M.toggle()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_float_term { buf = state.floating.buf }
    if vim.bo[state.floating.buf].buftype ~= 'terminal' then
      vim.fn.termopen(vim.o.shell)
      vim.cmd 'startinsert'
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

return M
