describe("collect_results", function()
  
  local collect_results
  
  before_each(function()
    -- Mock vim global
    _G.vim = {
      tbl_map = function(func, tbl)
        local result = {}
        for i, v in ipairs(tbl) do
          result[i] = func(v)
        end
        return result
      end,
      split = function(str, pattern)
        local result = {}
        for line in str:gmatch("[^\n]+") do
          table.insert(result, line)
        end
        return result
      end
    }
    
    -- Mock dependencies
    package.loaded['neotest.lib'] = {
      files = {
        find = function() return { '/tmp/test-results.xml' } end,
        read = function() return '<testsuite><testcase name="test" classname="Test"/></testsuite>' end
      }
    }
    
    package.loaded['neotest.lib.xml'] = {
      parse = function()
        return {
          testsuite = {
            testcase = {
              { _attr = { name = 'shouldWork', classname = 'com.example.MyTest' } },
              { _attr = { name = 'paramTest(String)', classname = 'com.example.MyTest' } },
              { _attr = { name = 'nestedTest', classname = 'com.example.MyTest$Nested' } }
            }
          }
        }
      end
    }
    
    package.loaded['neotest-gradle.hooks.shared_utilities'] = {
      get_package_name = function() return 'com.example' end
    }
    
    -- Clear module cache
    package.loaded['neotest-gradle.hooks.collect_results'] = nil
    collect_results = require('neotest-gradle.hooks.collect_results')
  end)
  
  local function create_tree(positions)
    return {
      iter = function()
        local i = 0
        return function()
          i = i + 1
          if i <= #positions then
            return i, positions[i]  -- Return index, position (like real neotest)
          else
            return nil
          end
        end
      end,
      data = function() 
        return { path = '/test/file.java' } 
      end
    }
  end
  
  it("should match JUnit4 test results with parameter stripping", function()
    local tree = create_tree({
      { id = 'com.example.MyTest.shouldWork', path = '/path/to/test.java' },
      { id = 'com.example.MyTest.paramTest', path = '/path/to/test.java' }
    })
    
    local results = collect_results(
      { context = { test_resuls_directory = '/tmp' } }, 
      nil, 
      tree
    )
    
    assert.is_not_nil(results['com.example.MyTest.shouldWork'])
    assert.is_not_nil(results['com.example.MyTest.paramTest']) -- paramTest(String) -> paramTest
    assert.are.equal('passed', results['com.example.MyTest.shouldWork'].status)
  end)
  
  it("should match Jupiter nested class results", function()
    local tree = create_tree({
      { id = 'com.example.MyTest.Nested.nestedTest', path = '/path/to/test.java' }
    })
    
    local results = collect_results(
      { context = { test_resuls_directory = '/tmp' } }, 
      nil, 
      tree
    )
    
    assert.is_not_nil(results['com.example.MyTest.Nested.nestedTest']) -- Test$Nested -> Test.Nested
    assert.are.equal('passed', results['com.example.MyTest.Nested.nestedTest'].status)
  end)
  
end)
