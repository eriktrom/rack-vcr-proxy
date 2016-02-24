#!/usr/bin/env ruby
require 'dotenv'
Dotenv.load

require 'rack'
require 'vcr'
require 'rack/reverse_proxy'
require 'json'
require 'pry'
require_relative 'lib/proxy_builder'

proxy_builder = ProxyBuilder.new

VCR.configure do |c|
  c.cassette_library_dir = proxy_builder.cassette_library_dir
  c.hook_into :webmock
  c.debug_logger = File.new("#{ENV['CASSETTES']}/vcr-recorder-debug.log", 'a+')

  c.default_cassette_options = {
    :update_content_length_header => true,
    :match_requests_on => [:method, :host, :query],
    :preserve_exact_body_bytes => proxy_builder.preserve_exact_body_bytes
  }

  c.ignore_localhost = proxy_builder.ignore_localhost

  c.before_record do |recording|
    proxy_builder.format recording
    # recording.response.body.force_encoding('utf-8')
  end
end

builder = Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::ShowExceptions

  use VCR::Middleware::Rack do |cassette, env|
    proxy_builder.env = env
    cassette.options proxy_builder.record_options

    if proxy_builder.is_login_redirect
      cassette.name proxy_builder.cassette_name('redirect')
    elsif proxy_builder.is_login_success
      cassette.name proxy_builder.cassette_name('success')
    else
      cassette.name proxy_builder.cassette_name
    end
  end

  use Rack::ReverseProxy do |env|
    reverse_proxy proxy_builder.reverse_proxy_path, proxy_builder.endpoint
  end

  run Proc.new {|env| [200, {}]}
end

Rack::Server.start :app => builder, :Port => proxy_builder.proxy_port if __FILE__ == $0
