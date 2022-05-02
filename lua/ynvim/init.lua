local vim = vim
local utils = require'ynvim.utils'
local M = {}

M.getConfig = function(filename)
  local config = utils.load(filename)
  for _, filename in ipairs(config.includes or {}) do
    local file = utils.load(filename)
    config = utils.merge(config, file)
  end
  return config
end

M.packer = function(plugins)
  local packer = require'packer'
  packer.reset()
  packer.init()
  for name, desc in pairs(plugins or {}) do
    local plugin = desc
    if type(plugin) == 'string' then
      plugin = {plugin}
    end
    if type(name) == 'string' then
      plugin.as = name
    end
    if plugin.enabled ~= false then
      plugin[1] = plugin._ or plugin[1]
      M.let(plugin.globals or {})
      M.set(plugin.options or {})
      M.map(plugin.mappings or {})
      loadstring(plugin.config or "")()
      M.aug("plugins." .. name, plugin.autocmds)
      for req, opts in pairs(plugin.setup or {}) do
        require(req).setup(utils.eval(opts))
      end
      for plug, opts in pairs(plugin.requires or {}) do
        if type(opts) == 'table' then
          opts[1] = opts._ or opts[1]
        end
        plugin.requires[plug] = opts
      end
      packer.use(plugin)
    end
  end
end

M.colorscheme = function(colorscheme)
  vim.api.nvim_command('colorscheme ' .. colorscheme)
end

M.set = function(options)
  for opt, val in pairs(utils.eval(options)) do
    vim.api.nvim_set_option(opt, val)
  end
end

M.let = function(variables)
  for name, value in pairs(utils.eval(variables)) do
    vim.api.nvim_set_var(name, value)
  end
end

M.map = function(mappings)
  for mode, map in pairs(mappings or {}) do
    for _, m in ipairs(map) do
      local opts = m[3] or {}
      opts.noremap = true
      opts.silent = true
      local lhs = m[1]
      local rhs = m[2]
      if type(rhs) == 'table' then
        opts.callback = rhs.callback
        rhs = rhs.callback
      elseif type(rhs) == 'function' then
        opts.callback = rhs
        rhs = '<Nop>'
      end
      if opts.buffer then
	opts.buffer = nil
	vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
      else
	vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
      end
    end
  end
end

M.aug = function(name, list) -- TODO: use lua nvim_create_autocmd
  if list then
    vim.cmd('aug ' .. name .. '\nau!\nau '  ..
       table.concat(list, '\nau ') .. '\naug END')
  end
end

M.setup = function(filename)
  local config = M.getConfig(filename)
  M.let(config.globals)
  M.set(config.options)
  M.map(config.mappings)
  M.aug(config.autocmds)
  M.packer(config.plugins)
  M.colorscheme(config.colorscheme)
end

return M
