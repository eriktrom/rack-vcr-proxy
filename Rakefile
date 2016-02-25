require 'dotenv/tasks'

desc 'Run in pre-recorded mode. Use this only for recording one interaction'
task :start, [:cassette_name] => :dotenv do |t, args|
  system "rackup -p #{ENV['PROXY_PORT'] || 9001}"
end

desc 'Run a re-record a new session. Use this overwriting current cassettes'
task :start_new_session, [:cassette_name] => :dotenv do |t, args|
  system "VCR_RECORDER_NEW_SESSION=1 rackup -p #{ENV['PROXY_PORT'] || 9001}"
end
