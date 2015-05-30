require 'dotenv'
Dotenv.load

require 'rack'
require 'vcr'
require 'rack/reverse_proxy'
require_relative 'proxy_builder'

proxy_builder = ProxyBuilder.new(host: ENV['HOST'])

VCR.configure do |c|
  c.cassette_library_dir = ENV['CASSETTES']
  c.hook_into :webmock
  c.debug_logger = File.new("#{ENV['CASSETTES']}/vcr-recorder-debug.log", 'a+')

  c.default_cassette_options = { :update_content_length_header => true }

  c.before_record do |i|
    # pretty print request and response json body's
    type = Array(i.response.headers['Content-Type']).join(',').split(';').first
    code = i.response.status.code

    if type =~ /[\/+]json$/ or 'text/javascript' == type
      begin
        request_body = JSON.parse i.request.body
        response_body = JSON.parse i.response.body
      rescue
        if code != 404
          puts
          warn "VCR: JSON parse error for Content-type #{type}"
          warn "Your unparseable json is: " + i.response.body.inspect
          puts
        end
      else
        i.request.body = JSON.pretty_generate request_body
        i.response.body = JSON.pretty_generate response_body
      end
    end

    # otherwise Ruby 2.0 will default to UTF-8:
    i.response.body.force_encoding('US-ASCII')
  end
end

builder = Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::ShowExceptions
  use VCR::Middleware::Rack do |cassette, env|
    cassette.name proxy_builder.cassette_name(env)
    use Rack::ReverseProxy do |env|
      reverse_proxy '/*', proxy_builder.endpoint
    end
  end

  run Proc.new {|env| [200, {}]}
end

Rack::Server.start :app => builder, :Port => 9001 if __FILE__ == $0
