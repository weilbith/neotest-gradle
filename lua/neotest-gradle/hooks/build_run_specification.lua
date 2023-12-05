local lib = require('neotest.lib')
local find_project_directory = require('neotest-gradle.hooks.find_project_directory')

--- Fiends either an executable file named `gradlew` in any parent directory of
--- the project or falls back to a binary called `gradle` that must be available
--- in the users PATH.
---
--- @param project_directory string
--- @return string - absolute path to wrapper of binary name
local function get_gradle_executable(project_directory)
  local gradle_wrapper_folder = lib.files.match_root_pattern('gradlew')(project_directory)
  local gradle_wrapper_found = gradle_wrapper_folder ~= nil

  if gradle_wrapper_found then
    return gradle_wrapper_folder .. lib.files.sep .. 'gradlew'
  else
    return 'gradle'
  end
end

--- Runs the given Gradle executable in the respective project directory to
--- query the `testResultsDir` property. Has to do so some plain text parsing of
--- the Gradle command output. The child folder named `test` is always added to
--- this path.
--- Is empty is directory could not be determined.
---
--- @param gradle_executable string
--- @param project_directory string
--- @return string - absolute path of test results directory
local function get_test_results_directory(gradle_executable, project_directory)
  local command = {
    gradle_executable,
    '--project-dir',
    project_directory,
    'properties',
    '--property',
    'testResultsDir',
  }
  local _, output = lib.process.run(command, { stdout = true })
  local output_lines = vim.split(output.stdout or '', '\n')

  for _, line in pairs(output_lines) do
    if line:match('testResultsDir: ') then
      return line:gsub('testResultsDir: ', '') .. lib.files.sep .. 'test'
    end
  end

  return ''
end

--- Takes a NeoTest tree object and iterate over its positions. For each position
--- it traverses up the tree to find the respective namespace that can be
--- used to filter the tests on execution. The namespace is usually the parent
--- test class.
---
--- @param tree table - see neotest.Tree
--- @return  table[] - list of neotest.Position of `type = "namespace"`
local function get_namespaces_of_tree(tree)
  local namespaces = {}

  for _, position in tree:iter() do
    if position.type == 'namespace' then
      table.insert(namespaces, position)
    end
  end

  return namespaces
end

--- Constructs the additional arguments for the test command to filter the
--- correct tests that should run.
--- Therefore it uses (and possibly repeats) the Gradle test command
--- option `--tests` with the full locator. The locators consist of the
--- package path, plus optional class names and test function name. This value is
--- already attached/pre-calculated to the nodes `id` property in the tree.
--- The position argument defines what the user intended to execute, which can
--- also be a whole file. In that case the paths are unknown and must be
--- collected by some additional logic.
---
--- @param tree table - see neotest.Tree
--- @param position table - see neotest.Position
--- @return string[] - list of strings for arguments
local function get_test_filter_arguments(tree, position)
  local arguments = {}

  if position.type == 'test' or position.type == 'namespace' then
    vim.list_extend(arguments, { '--tests', "'" .. position.id .. "'" })
  elseif position.type == 'file' then
    local namespaces = get_namespaces_of_tree(tree)

    for _, namespace in pairs(namespaces) do
      vim.list_extend(arguments, { '--tests', "'" .. namespace.id .. "'" })
    end
  end

  return arguments
end

--- See Neotest adapter specification.
---
--- In its core, it builds a command to start Gradle correctly in the project
--- directory with a test filter based on the positions.
--- It also determines the folder where the resulsts will be reported to, to
--- collect them later on. That folder path is saved to the context object.
---
--- @param arguments table - see neotest.RunArgs
--- @return nil | table | table[] - see neotest.RunSpec[]
return function(arguments)
  local position = arguments.tree:data()
  local project_directory = find_project_directory(position.path)
  local gradle_executable = get_gradle_executable(project_directory)
  local command = { gradle_executable, '--project-dir', project_directory, 'test' }
  vim.list_extend(command, get_test_filter_arguments(arguments.tree, position))

  local context = {}
  context.test_resuls_directory = get_test_results_directory(gradle_executable, project_directory)

  return { command = table.concat(command, ' '), context = context }
end
