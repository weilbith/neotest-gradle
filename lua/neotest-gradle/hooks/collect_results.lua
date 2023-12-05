local lib = require('neotest.lib')
local xml = require('neotest.lib.xml')
local get_package_name = require('neotest-gradle.hooks.shared_utilities').get_package_name

local XML_FILE_SUFFIX = '.xml'
local STATUS_PASSED = 'passed' --- see neotest.Result.status
local STATUS_FAILED = 'failed' --- see neotest.Result.status

--- Searches for all files XML files in this directory (not recursive) and
--- parses their content as Lua tables using some Neotest utility.
---
--- @param directory_path string
--- @return table[] - list of parsed XML tables
local function parse_xml_files_from_directory(directory_path)
  local xml_files = lib.files.find(directory_path, {
    filter_dir = function(file_name)
      return file_name:sub(-#XML_FILE_SUFFIX) == XML_FILE_SUFFIX
    end,
  })

  return vim.tbl_map(function(file_path)
    local content = lib.files.read(file_path)
    return xml.parse(content)
  end, xml_files)
end

--- If the value is a list itself it gets returned as is. Else a new list will be
--- created with the value as first element.
--- E.g.: { 'a', 'b' } => { 'a', 'b' } | 'a' => { 'a' }
---
--- @param value any
--- @return table
local function asList(value)
  return (type(value) == 'table' and #value > 0) and value or { value }
end

--- This tries to find the position in the tree that belongs to this test case
--- result from the JUnit report XML. Therefore it parses the location from the
--- node attributes and compares it with the position information in the tree.
---
--- @param tree table - see neotest.Tree
--- @param test_case_node table - XML node of test case result
--- @return table | nil - see neotest.Position
local function find_position_for_test_case(tree, test_case_node)
  local function_name = test_case_node._attr.name:gsub('%(%)', '')
  local package_and_class = (test_case_node._attr.classname:gsub('%$', '%.'))

  for _, position in tree:iter() do
    if position.name == function_name and vim.startswith(position.id, package_and_class) then
      return position
    end
  end
end

--- Convert a JUnit failure report into a Neotest error. It parses the failure
--- message and removes the Exception path from it. Furthermore it tries to parse
--- the stack trace to find a line number within the executed test case.
---
--- @param failure_node table - XML node of failure report in of a test case
--- @param position table - matched Neotest position of this test case (see neotest.Position)
--- @return table - see neotest.Error
local function parse_error_from_failure_xml(failure_node, position)
  local type = failure_node._attr.type
  local message = (failure_node._attr.message:gsub(type .. '.*\n', ''))

  local stack_trace = failure_node[1] or ''
  local package_name = get_package_name(position.path)
  local line_number

  for _, line in ipairs(vim.split(stack_trace, '[\r]?\n')) do
    local pattern = '^.*at.+' .. package_name .. '.*%(.+..+:(%d+)%)$'
    local match = line:match(pattern)

    if match then
      line_number = tonumber(match) - 1
      break
    end
  end

  return { message = message, line = line_number }
end

--- See Neotest adapter specification.
---
--- This builds a list of test run results. Therefore it parses all JUnit report
--- files and traverses trough the reports inside. The reports are matched back
--- to Neotest positions.
--- It also tries to determine why and where a test possibly failed for
--- additional Neotest features like diagnostics.
---
--- @param build_specfication table - see neotest.RunSpec
--- @param tree table - see neotest.Tree
--- @return table<string, table> - see neotest.Result
return function(build_specfication, _, tree)
  local results = {}
  local position = tree:data()
  local results_directory = build_specfication.context.test_resuls_directory
  local juris_reports = parse_xml_files_from_directory(results_directory)

  for _, juris_report in pairs(juris_reports) do
    for _, test_suite_node in pairs(asList(juris_report.testsuite)) do
      for _, test_case_node in pairs(asList(test_suite_node.testcase)) do
        local matched_position = find_position_for_test_case(tree, test_case_node)

        if matched_position ~= nil then
          local failure_node = test_case_node.failure
          local status = failure_node == nil and STATUS_PASSED or STATUS_FAILED
          local short_message = (failure_node or {}).message
          local error = failure_node and parse_error_from_failure_xml(failure_node, position)
          local result = { status = status, short = short_message, errors = { error } }
          results[matched_position.id] = result
        end

        -- TODO: What to do here?
      end
    end
  end

  return results
end
