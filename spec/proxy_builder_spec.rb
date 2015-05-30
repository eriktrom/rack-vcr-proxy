require_relative '../proxy_builder'

RSpec.describe ProxyBuilder do

  describe 'required args' do
    it 'requires a host' do
      expect { ProxyBuilder.new }.to raise_error('Must provide a host via HOST env variable')
    end
  end

  describe 'A new normal proxy builder' do
    subject { ProxyBuilder.new host: 'example.com'}

    it 'port 80 by default' do
      expect(subject.port).to eq 80
    end

    it 'should set cassette library directory to cassettes by default' do
      expect(subject.cassette_library_dir).to eq 'cassettes'
    end

    it 'should set cassette library directory to cassettes by default' do
      subject = ProxyBuilder.new host: 'example.com', cassette_library_dir: 'blah'
      expect(subject.cassette_library_dir).to eq 'blah'
    end

    it 'with custom port' do
      subject = ProxyBuilder.new(host: 'example.com', port: 8000)
      expect(subject.port).to eq 8000
    end

    it 'https by default' do
      expect(subject.scheme).to eq 'https'
    end

    describe 'endpoint' do
      it 'should just proxy on through via /*' do
        expect(subject.endpoint).to eq 'https://example.com/*'
      end
    end

    context 'for normal path based cassette names' do
      it 'should not error when no query string' do
        env = {
          'REQUEST_PATH' => '/api/channels.history',
          'QUERY_STRING' => ''
        }

        expect(subject.cassette_name(env)).to eq "/api/channels.history"
      end
    end
  end

  describe 'A new proxy builder for slack' do
    subject { ProxyBuilder.new host: 'example.com', cassette_type: 'slack'}

    describe '#cassette_name' do
      it 'should be the rpc method + the channel name' do
        env = {
          'REQUEST_PATH' => '/api/channels.history',
          'QUERY_STRING' => 'channel=weirdalpha&token=xoxp-4171430250-4269000832-4803857652-9ea521&something=good&token=abc'
        }

        expect(subject.cassette_name(env))
          .to eq 'channels.history-weirdalpha'
      end

      it 'should not error when no query string' do
        env = {
          'REQUEST_PATH' => '/api/channels.history',
          'QUERY_STRING' => ''
        }

        expect(subject.cassette_name(env)).to eq "channels.history-"
        expect{ subject.cassette_name(env) }.not_to raise_error
      end
    end
  end
end
