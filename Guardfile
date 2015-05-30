notification :growl

## Guard RSpec setup
#
# Usage: guard -P rspec

rspec_opts = {
  cmd: 'bundle exec rspec',
  run_all: { cmd: 'bundle exec rspec -r ./spec/support/spec_helper_run_all -f progress' },
  all_on_start: true,
  all_after_pass: true
}

guard :rspec, rspec_opts do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})               { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)/(.+)\.rb$}) { |m| "spec/#{m[1]}/#{m[2]}_spec.rb" }
  watch(%r{^(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }

  watch('spec/support/spec_helper.rb')  { "spec" }
  watch('spec/support/spec_helper_run_all.rb')  { "spec" }
end
