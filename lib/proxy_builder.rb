require 'dotenv'
Dotenv.load
require "rack"
require "json"
require 'pry'

class ProxyBuilder
  attr_accessor :scheme, :host, :port, :path, :query,
                :cassette_library_dir, :proxy_port, :env,
                :preserve_exact_body_bytes, :ignore_localhost,
                :http_settable_append_name

  attr_writer :reverse_proxy_path

  def env_to_bool env_var
    return false  if env_var == 0 || env_var.nil? || env_var.empty? || env_var =~ (/(false|f|no|n|0)$/i)
    return true   if env_var =~ (/(true|t|yes|y|1)$/i)
    raise ArgumentError.new("invalid value for ENV variable: \"#{env_var}\"")
  end

  def initialize host: nil,
                 port: ENV['PORT'] || '80',
                 proxy_port: ENV['PROXY_PORT'] || 9001, # TODO: remove me after rack cascade refactor (time permitting, lol)
                 scheme: ENV['SCHEME'] || 'https',
                 cassette_library_dir: ENV['CASSETTES'] || 'cassettes',
                 reverse_proxy_path: ENV['REVERSE_PROXY_PATH'] || '/*',
                 preserve_exact_body_bytes: env_to_bool(ENV['PRESERVE_EXACT_BODY_BYTES']),
                 ignore_localhost: env_to_bool(ENV['SHOULD_RACK_VCR_PROXY_IGNORE_LOCALHOST'])

    @host = host || ENV['HOST'] || (raise 'Must provide a host via HOST env variable')
    @scheme = scheme
    @port = port
    @cassette_library_dir = cassette_library_dir
    @proxy_port = proxy_port
    @reverse_proxy_path = reverse_proxy_path
    @preserve_exact_body_bytes = preserve_exact_body_bytes
    @ignore_localhost = ignore_localhost
  end


  # The cassette name, nested within a directory structure based on the upstream
  # endpoints path + method + query params
  #
  # @see [#query_path] and [#method] for more details on how cassettes are saved.
  def cassette_name append_name=false

    if append_name == 'redirect'
      ENV['VCR_RECORDER_LOGIN_REDIRECT'] = '0'
    elsif append_name == 'success'
      ENV['VCR_RECORDER_LOGIN_REDIRECT'] = '1'
    end

    append_name = http_settable_append_name unless append_name

    result = "#{path}/#{method}#{query_path}"

    if append_name && append_name.length > 0
      "#{result}/#{append_name}"
    else
      result
    end
  end

  def is_login
    env.fetch('REQUEST_PATH').downcase.include?('login')
  end

  def is_login_redirect
    is_login && ENV['VCR_RECORDER_LOGIN_REDIRECT'] == '1'
  end

  def is_login_success
    is_login && ENV['VCR_RECORDER_LOGIN_REDIRECT'] == '0'
  end

  def is_new_recording_session
    ENV['VCR_RECORDER_NEW_SESSION'] == '1'
  end

  def record_options
    is_new_recording_session ? {:record => :all} : {:record => :once}
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



  def format recording #change var name, lol
    Formatter.new(recording).format
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
    #     > /example.com
    #      > /love
    #        > /dogs
    #          > /GET
    #            > /query
    #              > /type-is-black
    #                > /breed-is-mutt
    #                  > /name-is-tobrecording.yml   <-- your cassette file for this request
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


  class Formatter

    attr_reader :recording, :type, :code

    def initialize(recording)
      @recording = recording
      @type = Array(recording.response.headers['Content-Type']).join(',').split(';').first
      @code = recording.response.status.code
    end

    def format
      case type
      when ('application/json' || 'text/javascript') then formatJson
      else
        # do nothing, this is optional behavior in the first place
      end
    end

    private

      def formatJson
        # copied from main rack file, obviously this could use some cleanup TODO

        if recording.request.body.length > 0
          # format request body
          begin
            if recording.request.body.is_a?(String)
              request_body = JSON.parse recording.request.body
            else
              request_body = recording.request.body
            end
          rescue
            if code != 404
              puts
              warn "VCR: JSON REQUEST parse error for Content-type #{type}"
              warn "Your unparseable REQUEST json is: " + recording.request.body.inspect
              puts
            end
          else
            recording.request.body = JSON.pretty_generate request_body
          end

          # format response body
          begin
            if recording.response.body.is_a?(String)
              response_body = JSON.parse recording.response.body
            else
              response_body = recording.response.body
            end
          rescue
            if code != 404
              puts
              warn "VCR: JSON RESPONSE parse error for Content-type #{type}"
              warn "Your unparseable RESPONSE json is: " + recording.response.body.inspect
              warn "Your unparseable raw RESPONSE json is: " + recording.response.body
              puts
            end
          else
            recording.response.body = JSON.pretty_generate response_body
          end
        end
      end
  end
end
