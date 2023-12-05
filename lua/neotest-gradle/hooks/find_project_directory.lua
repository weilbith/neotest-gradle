--- Construct function based on Neotest utility that finds root directory of
--- a potential Gradle project based on certain indicator files.
return require('neotest.lib').files.match_root_pattern('build.gradle', 'build.gradle.kts')
