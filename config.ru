require_relative "vcr_recorder"
run Rack::Cascade.new([VcrRecorder::App, VcrRecorder::Proxy])
