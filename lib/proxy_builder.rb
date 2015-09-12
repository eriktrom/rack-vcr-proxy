require 'dotenv'
Dotenv.load
require "rack"
require "json"
require 'pry'

class ProxyBuilder
  attr_accessor :scheme, :host, :port, :path, :query,
                :cassette_library_dir, :proxy_port, :env,
                :preserve_exact_body_bytes

  attr_writer :reverse_proxy_path

  def initialize host: nil,
                 port: ENV['PORT'] || '80',
                 proxy_port: ENV['PROXY_PORT'] || 9001,
                 scheme: ENV['SCHEME'] || 'https',
                 cassette_library_dir: ENV['CASSETTES'] || 'cassettes',
                 reverse_proxy_path: ENV['REVERSE_PROXY_PATH'] || '/*',
                 preserve_exact_body_bytes: ENV.fetch('PRESERVE_EXACT_BODY_BYTES', false)
    @host = host || ENV['HOST'] || (raise 'Must provide a host via HOST env variable')
    @scheme = scheme
    @port = port
    @cassette_library_dir = cassette_library_dir
    @proxy_port = proxy_port
    @reverse_proxy_path = reverse_proxy_path
    @preserve_exact_body_bytes = preserve_exact_body_bytes
  end


  # The cassette name, nested within a directory structure based on the upstream
  # endpoints path + method + query params
  #
  # @see [#query_path] and [#method] for more details on how cassettes are saved.
  def cassette_name env
      @env = env
      "#{path}/#{method}#{query_path}"
  end

  # Upstream endpoint to reverse proxy & record req/res cycles to/from
  #
  # @return [String] The upstream endpoing FQDN + path + query
  def endpoint
    "#{scheme}://#{host}#{suffix}#{reverse_proxy_path}"
  end

  # The path of the upstream service to reverse proxy to and thus record
  # cassettes for. By default this is set to /* and rarely needs a different
  # settings. A good example is if you only want to record images. Set this
  # to `images/*` in such a case.
  #
  # @return [String] String to append to upstream `endpoint` method for proxy recording
  def reverse_proxy_path
    splitter = /(.)/.match(@reverse_proxy_path)[0] == '/' ? '' : '/'
    star_suffix = /(\*)/.match(@reverse_proxy_path).nil? ? '/*' : ''
    "#{splitter}#{@reverse_proxy_path}#{star_suffix}"
  end

  private

    def suffix
      port == '80' ? "" : ":#{port}"
    end

    def path
      env.fetch('REQUEST_PATH')
    end

    # Modify this method to change how cassettes are named and where they are
    # stored when your endpoint deals with query strings. If you don't have query
    # strings, the docs here are relevant to how things work in general, thus
    # they remain informative.
    #
    # Given the url:
    #
    #   GET http://example.com/love/dogs?type=black&breed=mutt&name=tobi
    #
    # Your cassette will live in the following directory tree:
    #
    #   > /casseettes
    #     > /love
    #       > /dogs
    #         > /GET
    #           > /type-is-black
    #             > /breed-is-mutt
    #               > /name-is-tobi.yml   <-- your cassette file for this request
    #
    # @return [String] File directory path to a cassette file
    def query_path
      query_string = env.fetch('QUERY_STRING')
      return '' if query_string.empty?

      query_hash = Rack::Utils.parse_query(query_string)
      query_hash.each_pair.with_object(['/query']) { |(key, val), result|
        result << "/#{key}-is-#{val}"
      }.join()
    end

    # Request Method
    #
    # The request method is used when creating the directory structure for your
    # cassettes. If rack_reverse_proxy supports proxying the method through to
    # the upstream service, you will get a directory named, e.g., /GET under which
    # all /GET requests **to that endpoints path** where cassettes (which can be
    # futher nested via query params) can be saved.
    #
    # @see [#query_path] query_path for more a diagram of how cassettes are saved
    #
    # Known methods that work:
    #
    # - GET, POST, PUT, DELETE
    #
    # Iffy (b/c rack_reverse_proxy is old)
    #
    # - OPTIONS
    #
    # Not available (when i last checked)
    #
    # - PATCH
    #
    # If you know of a better reverse proxy middleware that supports all the verbs
    # drop an issue and I'll upgrade to a better library for that. :)
    #
    # @return [String] The name of the request method: GET/POST/PUT/DELETE/etc
    def method
      env.fetch('REQUEST_METHOD')
    end
end
