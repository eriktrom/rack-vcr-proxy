require 'dotenv/tasks'

desc 'Run in pre-recorded mode (handles digest login redirects as well)'
task start: :dotenv do
  sh "VCR_RECORDER_LOGIN_REDIRECT=1 ./vcr_recorder.rb"
end

desc 'Run a re-record a new session (when recordings require login through digest login)'
task start_new_session: :dotenv do
  sh "VCR_RECORDER_NEW_SESSION=1 VCR_RECORDER_LOGIN_REDIRECT=1 ./vcr_recorder.rb"
end
