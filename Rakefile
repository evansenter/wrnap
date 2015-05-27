require "bundler/gem_tasks"
require "rake/testtask"
require "active_record_migrations"
require "wrnap"

Rake::TestTask.new do |task|
  task.libs      << "test"
  task.test_files = FileList["test/**/test*.rb"].exclude("test/test_helper.rb")
end

desc "Run tests"
task :default => :test

ActiveRecordMigrations.load_tasks

ActiveRecord::Base.configurations = ActiveRecord::Tasks::DatabaseTasks.database_configuration = Wrnap.db.config
ActiveRecord::Tasks::DatabaseTasks.env = Wrnap.db.env
