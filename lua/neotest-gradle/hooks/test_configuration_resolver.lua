local logger = require("neotest.logging")

-- Function: extract_test_dir
-- Description: Extracts the directory name located between 'src' and 'java' in a given file path.
-- Parameters:
--   path (string): The full file path.
--   project_dir (string): The project directory path.
-- Returns:
--   test_dir (string) or nil: The name of the test directory or nil if not found.
local function extract_test_directory(path, project_directory)
    logger.info("Extracting test directory from path: " .. path .. " and project directory: " .. project_directory)

    -- Remove the projectDirectory from the path
    local relative_path = path:gsub('^' .. vim.pesc(project_directory), '')

    -- Remove any leading slash from the relative path
    relative_path = relative_path:gsub('^/', '')

    -- Use pattern matching to extract the name between 'src/' and '/java/'
    local something = relative_path:match('src/([^/]+)/java/')
    logger.info("Extracted test directory: " .. something)
    return something
end

local function get_test_configuration(arguments, test_directory)
    local test_configuration = nil
    if (arguments.test_configuration ~= nil) then
        test_configuration = arguments.test_configuration
    else
        if (test_directory ~= nil) then
            test_configuration = test_directory
        else
            test_configuration = 'test'
        end
    end
    logger.info("Using test configuration: " .. test_configuration)
    return test_configuration
end

return {
    extract_test_directory = extract_test_directory,
    get_test_configuration = get_test_configuration
}
