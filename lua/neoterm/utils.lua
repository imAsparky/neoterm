-- lua/neoterm/utils.lua
local M = {}

-- Function to convert command names to standardized format
function M.format_command_name(name, prefix)
  prefix = prefix or 'Neoterm'
  return prefix .. name
    :gsub('_(.)', function(c)
      return c:upper()
    end)
    :gsub('^%l', string.upper)
end

-- Function for path normalization
function M.normalize_path(path)
  -- Replace multiple consecutive slashes with a single slash
  local normalized = path:gsub('//+', '/')
  -- Remove trailing slash unless it's the root directory
  if #normalized > 1 and normalized:sub(-1) == '/' then
    normalized = normalized:sub(1, -2)
  end
  return normalized
end

-- Additional utility functions can be added here

return M
