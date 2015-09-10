# Rack VCR Proxy

Rack VCR Proxy will start a reverse proxy on port 9001 and record any
request/response cycles to relatively smartly named cassette files. 

Under the hood it uses [Rack Reverse Proxy](https://github.com/waterlink/rack-reverse-proxy) and [VCR](https://github.com/vcr/vcr).

## Usage

```
$ git clone https://github.com/eriktrom/rack-vcr-proxy.git
    
$ HOST=example.com CASSETTES=./my-path-to-saved-cassettes ruby vcr_recorder.rb
```

## Installation

Coming soon as a ruby gem. In the meantime use the instructions above.

## Environment Variables

Rack VCR Proxy uses the following environment variables to create a reverse proxy to an upstream service and record cassettes. Note all variables have a default value except for `HOST`.

```
ENV['HOST'] # => REQUIRED by you
ENV['PORT'] # => '80'
ENV['PROXY_PORT'] # => 9001
ENV['SCHEME'] # => 'https'
ENV['CASSETTES'] # => 'cassettes'
ENV['REVERSE_PROXY_PATH'] # => '/*'
ENV['PRESERVE_EXACT_BODY_BYTES'] # => false
```

Avoid putting these environment variables in your `.bash_profile` or similar, that's just bad habit.

They can be set via the command line when booting the proxy server or via something like [dotenv](https://github.com/bkeepers/dotenv). 

In the future perhaps a CLI will emerge to make passing flags and options easier. 

## Cassette Naming

Given the URL:

    GET https://example.com/love/dogs?type=black&breed=mutt&name=tobi

When you run:

    HOST=example.com ruby vcr_recorder.rb

Your cassette will live in the following directory tree:

```
> /casseettes
  > /love
    > /dogs
      > /GET
        > /type-is-black
          > /breed-is-mutt
            > /name-is-tobi.yml   <-- your cassette file for this request
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eriktrom/rack-vcr-proxy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
