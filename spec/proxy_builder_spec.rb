require_relative '../lib/proxy_builder'

RSpec.describe ProxyBuilder do

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
  end
end
