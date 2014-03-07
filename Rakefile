require "bundler/gem_tasks"
require "rspec/core/rake_task"

require "rake/extensiontask"

Rake::ExtensionTask.new "mulligan" do |ext|
  ext.lib_dir = "lib/mulligan"
end

RSpec::Core::RakeTask.new(:spec => :compile)

task :default => :spec
