return {
  name = 'gradle-test',
  root = require('neotest-gradle.hooks.find_project_directory'),
  is_test_file = require('neotest-gradle.hooks.is_test_file'),
  discover_positions = require('neotest-gradle.hooks.discover_positions'),
  build_spec = require('neotest-gradle.hooks.build_run_specification'),
  results = require('neotest-gradle.hooks.collect_results'),
}
