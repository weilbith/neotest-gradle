local lib = require('neotest.lib')
local logger = require('neotest.logging')

-- TODO: How to improve using Treesitter or similar?
--- @param file_path string
local function get_package_name(file_path)
  local lines = lib.files.read_lines(file_path)
  for _, line in ipairs(lines) do
    if string.match(line, '^package ') then
      local package_name = line:gsub('^package ', ''):gsub(';', '')

      logger.debug('resolved package: ' .. package_name)
      return package_name
    end
  end

  logger.warn('failed to resolve a package in ' .. file_path)
  return nil
end

return {
  get_package_name = get_package_name,
}
