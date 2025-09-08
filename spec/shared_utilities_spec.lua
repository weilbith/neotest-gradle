describe("shared_utilities", function()
  
  before_each(function()
    package.loaded['neotest.lib'] = {
      files = {
        read_lines = function(file_path)
          if file_path == 'test.java' then
            return { 'package com.example.test;', 'public class Test {}' }
          elseif file_path == 'test.kt' then
            return { '    package com.example.kotlin', 'class Test' }
          elseif file_path == 'empty.java' then
            return { 'public class Test {}' }
          end
          return {}
        end
      }
    }
  end)
  
  describe("get_package_name", function()
    it("should extract Java package", function()
      local shared_utilities = require('neotest-gradle.hooks.shared_utilities')
      local result = shared_utilities.get_package_name('test.java')
      assert.are.equal('com.example.test', result)
    end)
    
    it("should extract Kotlin package", function()
      local shared_utilities = require('neotest-gradle.hooks.shared_utilities')
      local result = shared_utilities.get_package_name('test.kt')
      assert.are.equal('com.example.kotlin', result)
    end)
    
    it("should return empty string when no package", function()
      local shared_utilities = require('neotest-gradle.hooks.shared_utilities')
      local result = shared_utilities.get_package_name('empty.java')
      assert.are.equal('', result)
    end)
  end)
end)
