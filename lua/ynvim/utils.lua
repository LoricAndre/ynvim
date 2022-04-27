local yaml = require'lyaml'
local M = {}

local getKeys = function(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

local isLua = function(t)
  local keys = getKeys(t)
  if #keys == 1 and keys[1] == 'lua' then
    return true
  end
  return false
end

M.eval = function(obj)
  for key, value in pairs(obj or {}) do
    if type(value) == 'table' then
      if isLua(value) then
          obj[key] = loadstring('return ' .. value.lua)()
      else
        obj[key] = M.eval(value)
      end
    end
  end
  return obj or {}
end


M.load = function(filename)
  local file = io.open(vim.fn.expand(vim.fn.stdpath('config') .. '/' .. filename), 'r')
  local config = {}
  if file then
    config = yaml.load(file:read('*all'))
    file:close()
  else
    print('Could not load config file: ' .. filename)
  end
  return config
end

M.merge = function(t1, t2)
  for k, v in pairs(t2) do
      if (type(v) == "table") and (type(t1[k] or false) == "table") then
          t1[k] = M.merge(t1[k], t2[k])
      else
          t1[k] = v
      end
  end
  return t1
end

return M
