require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |task|
  task.libs      << "test"
  task.test_files = FileList["test/**/test*.rb"].exclude("test/test_helper.rb")
end

desc "Run tests"
task :default => :test
