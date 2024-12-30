-- lua/neoterm/utils.lua
local M = {}

-- Function to convert command names to standardized format
-- @param name string: The base command name
-- @param prefix string: Optional prefix (defaults to 'Neoterm')
-- @return string: The formatted command name
function M.format_command_name(name, prefix)
  prefix = prefix or 'Neoterm'
  return prefix .. name
    :gsub('_(.)', function(c)
      return c:upper()
    end)
    :gsub('^%l', string.upper)
end

-- Additional utility functions can be added here

return M
