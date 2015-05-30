require 'pry'

RSpec.configure do |config|

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.run_all_when_everything_filtered = true

  config.filter_run :only
  config.alias_example_to :only, :only => true
  config.alias_example_group_to :onlyg, :only => true

  config.filter_run_excluding :skip
  config.alias_example_to :skip, :skip => true
  config.alias_example_group_to :skipg, :skip => true

  config.alias_example_group_to :feature
  config.alias_example_group_to :scenario

  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed
end


