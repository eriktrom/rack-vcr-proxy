require_relative '../lib/proxy_builder'

RSpec.describe ProxyBuilder do

  ProxyBuilder.class_eval do
    public :query_path, :path
  end

  before do
    ENV['HOST'] = 'example.com'
    ENV['PORT'] = '80'
    ENV['PROXY_PORT'] = '9001'
    ENV['SCHEME'] = 'https'
    ENV['CASSETTES'] = 'cassettes'
  end

  describe 'required args' do
    it 'requires a host' do
      ENV['HOST'] = nil
      expect { ProxyBuilder.new }.to raise_error('Must provide a host via HOST env variable')
    end
  end

  describe 'A new normal proxy builder' do
    subject { ProxyBuilder.new }

    it 'port 80 by default' do
      expect(subject.port).to eq '80'
    end

    it 'should have a proxy port of 9001 by default' do
      expect(subject.proxy_port).to eq '9001'
    end

    it 'should have a proxy port of 9001 by default' do
      expect(subject.proxy_port).to eq '9001'
    end

    it 'should set cassette library directory to cassettes by default' do
      expect(subject.cassette_library_dir).to eq 'cassettes'
    end

    it 'should set cassette library directory to cassettes by default' do
      subject = ProxyBuilder.new cassette_library_dir: 'blah'
      expect(subject.cassette_library_dir).to eq 'blah'
    end

    it 'with custom port' do
      subject.port = 8000
      expect(subject.port).to eq 8000
    end

    it 'https by default' do
      expect(subject.scheme).to eq 'https'
    end

    describe 'endpoint' do
      it 'should just proxy on through via /*' do
        expect(subject.endpoint).to eq 'https://example.com/*'
      end

      it 'should correctly build the right url to forward to' do
        subject = ProxyBuilder.new host: 'blah.com', port: 8000
        expect(subject.endpoint).to eq 'https://blah.com:8000/*'
      end

      it 'should proxy a certain path when the reverse_proxy_path is provided' do
        subject = ProxyBuilder.new host: 'blah.com', port: 8000, reverse_proxy_path: '/images/*'
        expect(subject.endpoint).to eq 'https://blah.com:8000/images/*'
      end

      it 'path.resolve reverse_proxy_path to make this test not run 8000images together' do
        subject = ProxyBuilder.new host: 'blah.com', port: 8000, reverse_proxy_path: 'images/*'
        expect(subject.endpoint).to eq 'https://blah.com:8000/images/*'
      end

      it 'path.resolve reverse_proxy_path to make this test not run 8000images together' do
        subject = ProxyBuilder.new host: 'blah.com', reverse_proxy_path: 'images/*'
        expect(subject.endpoint).to eq 'https://blah.com/images/*'
      end

      it 'will put the * on the end if its not present' do
        subject = ProxyBuilder.new host: 'blah.com', reverse_proxy_path: 'images'
        expect(subject.endpoint).to eq 'https://blah.com/images/*'
      end
    end

    context 'for normal path based cassette names' do
      it 'should not error when no query string' do
        env = {
          'REQUEST_METHOD' => 'GET',
          'REQUEST_PATH' => '/api/channels.history',
          'QUERY_STRING' => ''
        }

        expect(subject.cassette_name(env)).to eq "/api/channels.history/GET"
      end
    end

    context 'query_path' do
      it 'should return a / seperated string starting with the word query' do
        subject.env = {
          'QUERY_STRING' => 'something=foo&best-language=ruby'
        }

        expect(subject.query_path).to eq "/query/something-is-foo/best-language-is-ruby"
      end

      it 'should return an empty string when no QUERY_STRING is provided' do
        subject.env = {
          'QUERY_STRING' => ''
        }

        expect(subject.query_path).to eq ''
      end
    end

    context '#cassette_name' do
      it 'concats REQUEST_METHOD, REQUEST_PATH and QUERY_STRING to form the cassette name (and fs path)' do
        env = {
          'REQUEST_METHOD' => 'GET',
          'REQUEST_PATH' => 'api/channels.history',
          'QUERY_STRING' => 'something=foo&best-language=ruby'
        }

        expect(subject.cassette_name(env)).to eq "api/channels.history/GET/query/something-is-foo/best-language-is-ruby"
      end

      it 'handles empty query string' do
        env = {
          'REQUEST_METHOD' => 'GET',
          'REQUEST_PATH' => 'api/channels.history',
          'QUERY_STRING' => ''
        }

        expect(subject.cassette_name(env)).to eq "api/channels.history/GET"
      end
    end

    # A bit confusing but went this direction b/c the tests need some love and
    # without love, they we're actually lying to me (albeit for good reason, I
    # was neglecting them)
    #
    # ENV['HOST'] is the only required
    context '#preserve_exact_body_bytes' do
      def set_env val
        ENV['PRESERVE_EXACT_BODY_BYTES'] = val
      end

      before do
        ENV.delete('PRESERVE_EXACT_BODY_BYTES')
      end

      it 'should return false by default' do
        expect(subject.preserve_exact_body_bytes).to eq false
      end

      it 'with preserve_exact_body_bytes "(true|t|yes|y|1)" string' do
        # turn into 'it should behave like'

        set_env 'true'
        expect(subject.preserve_exact_body_bytes).to eq true

        set_env 't'
        expect(subject.preserve_exact_body_bytes).to eq true

        set_env 'y'
        expect(subject.preserve_exact_body_bytes).to eq true

        set_env '1'
        expect(subject.preserve_exact_body_bytes).to eq true
      end

      it 'with preserve_exact_body_bytes "(false|f|no|n|0)" string' do
        # turn into 'it should behave like'

        set_env nil
        expect(subject.preserve_exact_body_bytes).to eq false

        set_env ''
        expect(subject.preserve_exact_body_bytes).to eq false

        set_env 'false'
        expect(subject.preserve_exact_body_bytes).to eq false

        set_env 'f'
        expect(subject.preserve_exact_body_bytes).to eq false

        set_env 'n'
        expect(subject.preserve_exact_body_bytes).to eq false

        set_env '0'
        expect(subject.preserve_exact_body_bytes).to eq false
      end
    end

    context '#ignore_localhost' do
      def set_env val
        ENV['SHOULD_RACK_VCR_PROXY_IGNORE_LOCALHOST'] = val
      end

      before do
        ENV.delete('SHOULD_RACK_VCR_PROXY_IGNORE_LOCALHOST')
      end

      it 'should return false by default' do
        expect(subject.ignore_localhost).to eq false
      end

      it 'with ignore_localhost "(true|t|yes|y|1)" string' do
        # turn into 'it should behave like'

        set_env 'true'
        expect(subject.ignore_localhost).to eq true

        set_env 't'
        expect(subject.ignore_localhost).to eq true

        set_env 'y'
        expect(subject.ignore_localhost).to eq true

        set_env '1'
        expect(subject.ignore_localhost).to eq true
      end

      it 'with preserve_exact_body_bytes "(false|f|no|n|0)" string' do
        # turn into 'it should behave like'

        set_env nil
        expect(subject.ignore_localhost).to eq false

        set_env ''
        expect(subject.ignore_localhost).to eq false

        set_env 'false'
        expect(subject.ignore_localhost).to eq false

        set_env 'f'
        expect(subject.ignore_localhost).to eq false

        set_env 'n'
        expect(subject.ignore_localhost).to eq false

        set_env 'no'
        expect(subject.ignore_localhost).to eq false

        set_env '0'
        expect(subject.ignore_localhost).to eq false
      end
    end
  end
end
