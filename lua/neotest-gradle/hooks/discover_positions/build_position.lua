--- @param captured_nodes table
local function get_captured_node_type(captured_nodes)
  if captured_nodes['test.name'] then
    return 'test'
  end
  if captured_nodes['namespace.name'] then
    return 'namespace'
  end
end

--- Try to convert camel case function names from Java to something more text
--- alike as you can do in Kotlin.
--- For example `itShouldFailIfBroken` becomes `it should fail if broken`.
--- Works not too well for many cases and is open to improvements.
---
--- @param text string
--- @return string
local function camel_case_to_lower_case_with_whitespaces(text)
  return (text:gsub('([A-Z])', function(character)
    return ' ' .. character:lower()
  end))
end

--- Try to improve the raw function name into something nicely readable. This
--- includes removing "noisy" characters from the Treesitter parsing as well as
--- converting camel case naming and similar.
---
--- @param name string - name of the test function
--- @return string
local function beautify_name(name)
  local clean_name = (name:gsub('`', ''):gsub('"', ''))
  local has_whitespaces = clean_name:match(' ') and true or false
  local descriptive_name = has_whitespaces and clean_name
    or camel_case_to_lower_case_with_whitespaces(clean_name)
  return (descriptive_name:gsub('^ ', ''))
end

--- See neotest.lib.treesitter.ParseOptions.build_position
---
--- @param file_path string
--- @param source string
--- @param captured_nodes table
--- @return nil | table | table[] - see neotest.Position[]
return function(file_path, source, captured_nodes)
  local node_type = get_captured_node_type(captured_nodes)
  local handle_name = vim.treesitter.get_node_text(captured_nodes[node_type .. '.name'], source)
  local definition = captured_nodes[node_type .. '.definition']
  local has_display_name = captured_nodes['display_name.value'] ~= nil
  local display_name = has_display_name
    and vim.treesitter.get_node_text(captured_nodes['display_name.value'], source)
  local name = beautify_name(display_name or handle_name)

  return {
    type = node_type,
    path = file_path,
    name = name,
    handle_name = handle_name,
    range = { definition:range() },
  }
end
