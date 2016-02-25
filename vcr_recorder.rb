require 'dotenv'
Dotenv.load

require "sinatra/base"
require 'vcr'
require 'rack/reverse_proxy'
require_relative 'lib/proxy_builder'

ENV['VCR_RECORDER_LOGIN_REDIRECT'] = '1' # TODO: remove all ENV vars, EVERYWHERE

module VcrRecorder

  def self.proxy_builder
    @proxy_builder ||= ProxyBuilder.new
  end

  class Proxy < Sinatra::Base

    configure do
      set :timeout, 120
      enable :logging
    end

    VCR.configure do |c|
      c.cassette_library_dir = VcrRecorder.proxy_builder.cassette_library_dir
      c.hook_into :webmock
      c.debug_logger = File.new("#{ENV['CASSETTES']}/vcr-recorder-debug.log", 'a+')

      c.default_cassette_options = {
        :update_content_length_header => true,
        :match_requests_on => [:method, :host, :query],
        :preserve_exact_body_bytes => VcrRecorder.proxy_builder.preserve_exact_body_bytes
      }

      c.ignore_localhost = VcrRecorder.proxy_builder.ignore_localhost

      c.before_record do |recording|
        VcrRecorder.proxy_builder.format recording
        # recording.response.body.force_encoding('utf-8')
      end
    end

    use VCR::Middleware::Rack do |cassette, env|
      VcrRecorder.proxy_builder.env = env
      cassette.options VcrRecorder.proxy_builder.record_options

      if VcrRecorder.proxy_builder.is_login_redirect
        cassette.name VcrRecorder.proxy_builder.cassette_name('redirect')
      elsif VcrRecorder.proxy_builder.is_login_success
        cassette.name VcrRecorder.proxy_builder.cassette_name('success')
      else
        cassette.name VcrRecorder.proxy_builder.cassette_name
      end
    end

    use Rack::ReverseProxy do |env|
      reverse_proxy VcrRecorder.proxy_builder.reverse_proxy_path, VcrRecorder.proxy_builder.endpoint, :timeout => 120
    end
  end

  class App < Sinatra::Base

    configure do
      enable :logging
    end

    get '/set-cassette/:name' do
      VcrRecorder.proxy_builder.http_settable_append_name = params[:name]

      <<-HTML
      <h1>
        You've successfully set the current cassette to
        #{VcrRecorder.proxy_builder.http_settable_append_name}
      </h1>
      HTML
    end

    get '/current-cassette' do
      current_cassette_name = VcrRecorder.proxy_builder.http_settable_append_name || 'Sorry no current cassette name set'

      <<-HTML
      <h1>
        The currently set appendable name for the next cassette recording
        is #{current_cassette_name}
      </h1>
      HTML
    end

    get '/reset' do
      VcrRecorder.proxy_builder.http_settable_append_name = false
      "Appendable name for next cassette has been removed!"
    end

    get('/*') { not_found }
  end

end
