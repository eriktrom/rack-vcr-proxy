require "rack"

require 'pry'

class ProxyBuilder
  attr_accessor :scheme, :host, :port, :path, :query

  def initialize host:, scheme: 'https', port: 80
    @host = host
    @scheme = scheme
    @port = port == 80 ? '' : port
  end

  def endpoint
    scheme + '://' + host + '/*'
  end

  def cassette_name env
    channel = Rack::Utils
      .parse_query(env.fetch('QUERY_STRING'))
      .fetch('channel') { '' }

    type = env.fetch('REQUEST_PATH').split('/').last
    type+'-'+channel
  end
end
