require "rack"

require 'pry'

class ProxyBuilder
  attr_accessor :scheme, :host, :port, :path, :query, :cassette_type, :cassette_library_dir

  def initialize host: nil, port: ENV['PORT'] || 80, scheme: ENV['SCHEME'] || 'https', cassette_type: 'normal', cassette_library_dir: ENV['CASSETTES'] || 'cassettes'
    @host = host || ENV['HOST'] || (raise 'Must provide a host via HOST env variable')
    @scheme = scheme
    @port = port
    @cassette_type = cassette_type
    @cassette_library_dir = cassette_library_dir
  end

  def endpoint
    suffix = port == 80 ? "/*" : ":#{port}/*"
    "#{scheme}://#{host}#{suffix}"
  end

  def cassette_name env
    channel = Rack::Utils
      .parse_query(env.fetch('QUERY_STRING'))
      .fetch('channel') { '' }

    if cassette_type == 'slack'
      type = env.fetch('REQUEST_PATH').split('/').last
      type+'-'+channel
    elsif cassette_type == 'normal'
      env.fetch('REQUEST_PATH')
    end
  end
end
