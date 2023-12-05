local TEST_FILE_PATTERNS = { 'Test.kt$', 'Test.java$' }

--- Predicate function to determine if a file is a test file or not
--- This simply checks if the file name matches certain patterns based on
--- convention.
---
--- Target for improvement with more sophisticated solutions.
---
--- @param file_path string
--- @return boolean
return function(file_path)
  for _, pattern in pairs(TEST_FILE_PATTERNS) do
    if file_path:match(pattern) then
      return true
    end
  end

  return false
end
