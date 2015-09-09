require 'dotenv'
Dotenv.load

require "rack"

require 'pry'

class ProxyBuilder
  attr_accessor :scheme, :host, :port, :path, :query,
                :cassette_library_dir, :proxy_port, :env,
                :reverse_proxy_path

  # TODO: only require host, not port and scheme - split host string if needed instead
  def initialize host: nil,
                 port: ENV['PORT'] || '80',
                 proxy_port: ENV['PROXY_PORT'] || 9001,
                 scheme: ENV['SCHEME'] || 'https',
                 cassette_library_dir: ENV['CASSETTES'] || 'cassettes',
                 reverse_proxy_path: ENV['REVERSE_PROXY_PATH'] || '/*'

    @host = host || ENV['HOST'] || (raise 'Must provide a host via HOST env variable')
    @scheme = scheme
    @port = port
    @cassette_library_dir = cassette_library_dir
    @proxy_port = proxy_port
    @reverse_proxy_path = reverse_proxy_path
  end

  def endpoint
    splitter = /(.)/.match(reverse_proxy_path)[0] == '/' ? '' : '/'
    star_suffix = /(\*)/.match(reverse_proxy_path).nil? ? '/*' : ''

    suffix = port == '80' ? "" : ":#{port}"
    "#{scheme}://#{host}#{suffix}#{splitter}#{reverse_proxy_path}#{star_suffix}"
  end

  def method
    env.fetch('REQUEST_METHOD')
  end

  def query_path
    query_string = env.fetch('QUERY_STRING')
    return '' if query_string.empty?

    query_hash = Rack::Utils.parse_query(query_string)
    query_hash.each_pair.with_object(['/query']) { |(key, val), result|
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
