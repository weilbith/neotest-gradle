local get_package_name = require('neotest-gradle.hooks.shared_utilities').get_package_name

--- Remove some "noisy" characters of the name. Like for test function names
--- with Kotlin using the backticks (e.g.: "fun `it should do something`()").
---
--- @param name string
--- @return string
local function get_clean_position_name(name)
  return (name:gsub('`', ''))
end

--- Namespaces are the (possibly nested) test classes. To correctly address such
--- a class, all its parent classes need to be concatenated as a Java path. The
--- final result always ends with a dot character, prepared to append the test
--- name or similar.
---
--- @param namespaces table[] -- see neotest.Position[]
--- @return string - e.g.: "UITest.AdminViewTest"
local function get_namespace_name(namespaces)
  local namespace_names = vim.tbl_map(function(namespace)
    return namespace.handle_name
  end, namespaces)

  local full_namespace = table.concat(namespace_names, '.')
  return #full_namespace > 0 and (full_namespace .. '.') or ''
end

--- See neotest.lib.positions.ParseOptions.position_id
---
--- The position identifier is set to the full locator of a test based on its
--- package, class(es) and function name. This can be used to address specific
--- test cases during execution.
---
--- @param position table - see neotest.Position
--- @param parents table[] - see neotest.position[]
--- @return string - e.g.: "org.company.product.UITest.AdminViewTest.itShouldDoSomething"
return function(position, parents)
  local package_name = get_package_name(position.path)
  local namespace_name = get_namespace_name(parents)
  local position_name = get_clean_position_name(position.handle_name)
  return package_name .. '.' .. namespace_name .. position_name
end
