puts "\n\n###\n###\nRunning spec_helper_run_all\n###\n###\n\n"

RSpec.configure do |config|
  # config.profile_examples = 10
  config.mock_with :rspec do |mocks|

    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true # for should_recieve

  end
end
