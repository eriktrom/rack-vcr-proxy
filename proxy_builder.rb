require 'dotenv'
Dotenv.load

require "rack"

require 'pry'

class ProxyBuilder
  attr_accessor :scheme, :host, :port, :path, :query,
                :cassette_library_dir, :proxy_port, :env

  # TODO: only require host, not port and scheme - split host string if needed instead
  def initialize host: nil,
                 port: ENV['PORT'] || '80',
                 proxy_port: ENV['PROXY_PORT'] || 9001,
                 scheme: ENV['SCHEME'] || 'https',
                 cassette_library_dir: ENV['CASSETTES'] || 'cassettes'

    @host = host || ENV['HOST'] || (raise 'Must provide a host via HOST env variable')
    @scheme = scheme
    @port = port
    @cassette_library_dir = cassette_library_dir
    @proxy_port = proxy_port
  end

  def endpoint
    suffix = port == '80' ? "/*" : ":#{port}/*"
    "#{scheme}://#{host}#{suffix}"
  end

  def method
    env.fetch('REQUEST_METHOD')
  end

  def query_path
    query_string = env.fetch('QUERY_STRING')
    return '' if query_string.empty?

    query_hash = Rack::Utils.parse_query(query_string)
    query_hash.each.with_object(['/query']) { |(key, val), result|
      result << "/#{key}-is-#{val}"
    }.join()
  end

  def path
    env.fetch('REQUEST_PATH')
  end

  def cassette_name env
      @env = env
      "#{path}/#{method}#{query_path}"
  end
end
