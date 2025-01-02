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

-- Set up terminal buffer options
local function setup_terminal(bufnr)
  -- Set buffer options
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].bufhidden = 'hide' -- Ensure the terminal is available until killed

  -- Start terminal in insert mode
  vim.cmd 'startinsert'

  -- Auto-enter insert mode when focusing terminal
  local term_group = vim.api.nvim_create_augroup('TerminalBehavior', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = term_group,
    buffer = bufnr,
    callback = function()
      if vim.bo[bufnr].buftype == 'terminal' then
        vim.cmd 'startinsert'
      end
    end,
  })
end

-- Create floating terminal window
local function create_float_term(opts)
  opts = opts or {}

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

  -- Debug info
  -- vim.notify(
  --   string.format(
  --     'Running command %s:\n  cmd exists: %s\n  cmd type: %s\n  command structure: %s',
  --     command_name,
  --     cmd and 'yes' or 'no',
  --     type(command),
  --     vim.inspect(command)
  --   ),
  --   vim.log.levels.INFO
  -- )

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

        vim.notify(string.format('Post Command %s', command.post_cmd), vim.log.levels.INFO)
        vim.fn.termopen(command.init, {
          env = {
            TERM = 'xterm-256color',
          },
        })

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

      vim.notify(string.format('Terminal Command %s', command), vim.log.levels.INFO)
      vim.fn.termopen(command, {
        env = {
          TERM = 'xterm-256color',
        },
      })

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
