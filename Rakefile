require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

def supports_mulligan?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9.3"
end

def uses_c_extension?
  supports_mulligan? && RUBY_VERSION < "2.0.0"
end

if uses_c_extension?
  require "rake/extensiontask"

  Rake::ExtensionTask.new "mulligan" do |ext|
    ext.lib_dir = "lib/mulligan"
  end
  task :spec => :compile
end
