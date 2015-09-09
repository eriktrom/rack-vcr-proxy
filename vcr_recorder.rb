require 'dotenv'
Dotenv.load

require 'rack'
require 'vcr'
require 'rack/reverse_proxy'
require 'json'
require_relative 'lib/proxy_builder'

proxy_builder = ProxyBuilder.new

VCR.configure do |c|
  c.cassette_library_dir = proxy_builder.cassette_library_dir
  c.hook_into :webmock
  c.debug_logger = File.new("#{ENV['CASSETTES']}/vcr-recorder-debug.log", 'a+')

  c.default_cassette_options = {
    :update_content_length_header => true,
    :match_requests_on => [:method, :host, :query]
  }

  c.before_record do |i|
    # pretty print request and response json body's
    type = Array(i.response.headers['Content-Type']).join(',').split(';').first
    code = i.response.status.code

    if type == ('application/json' || 'text/javascript')
      # pretty generate request body
      if i.request.body.length > 0
        begin
          if i.request.body.is_a?(String)
            request_body = JSON.parse i.request.body
          else
            request_body = i.request.body
          end
        rescue
          if code != 404
            puts
            warn "VCR: JSON REQUEST parse error for Content-type #{type}"
            warn "Your unparseable REQUEST json is: " + i.request.body.inspect
            puts
          end
        else
          i.request.body = JSON.pretty_generate request_body
        end
      end

      # pretty generate response body
      begin
        if i.response.body.is_a?(String)
          response_body = JSON.parse i.response.body
        else
          response_body = i.response.body
        end
      rescue
        if code != 404
          puts
          warn "VCR: JSON RESPONSE parse error for Content-type #{type}"
          warn "Your unparseable RESPONSE json is: " + i.response.body.inspect
          warn "Your unparseable raw RESPONSE json is: " + i.response.body
          puts
        end
      else
        i.response.body = JSON.pretty_generate response_body
      end
    end

    # otherwise Ruby 2.0 will default to UTF-8:
    # i.response.body.force_encoding('US-ASCII')
    i.response.body.force_encoding('UTF-8')
  end
end

builder = Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::ShowExceptions

  use VCR::Middleware::Rack do |cassette, env|
    cassette.name proxy_builder.cassette_name(env)
  end

  use Rack::ReverseProxy do |env|
    reverse_proxy proxy_builder.reverse_proxy_path, proxy_builder.endpoint
  end

  run Proc.new {|env| [200, {}]}
end

Rack::Server.start :app => builder, :Port => proxy_builder.proxy_port if __FILE__ == $0
