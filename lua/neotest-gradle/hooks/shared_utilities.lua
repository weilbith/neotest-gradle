local lib = require('neotest.lib')

--- @param file_path string The path of the file to parse.
--- @return string The package name or an empty string if not found.
local function get_package_name(file_path)
  local lines = lib.files.read_lines(file_path)

  for _, line in ipairs(lines) do
    -- Match package declaration (works for both Java and Kotlin)
    local package_match = line:match('^%s*package%s+([%w%.]+)')
    if package_match then
      return package_match
    end
  end

  return ''
end

return {
  get_package_name = get_package_name,
}
