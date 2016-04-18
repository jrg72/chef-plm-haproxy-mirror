require 'bundler/setup'
require 'foodcritic'
require 'kitchen/rake_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: 'test:quick'

RuboCop::RakeTask.new('style:ruby')

FoodCritic::Rake::LintTask.new('style:chef') do |t|
  t.options = {
    fail_tags: ['any']
  }
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['test/unit/**{,/*/**}/*_spec.rb']
  t.rspec_opts = '--default-path test/unit'
end

Kitchen::RakeTasks.new

task :style do
  Rake::Task['style:ruby'].invoke
  Rake::Task['style:chef'].invoke
end

namespace :test do
  task :quick do
    Rake::Task['style'].invoke
    Rake::Task['spec'].invoke
  end

  task :complete do
    Rake::Task['test:quick'].invoke
    Rake::Task['kitchen:all'].invoke
  end
end
