require 'httpclient'
require 'multi_json'

module YogaPants
  class Connection
    # This class is/will be an abstraction layer for the underlying
    # HTTP client.
    # TODO: Use https://github.com/rubiii/httpi so we don't have to deal
    # with interfacing with multiple HTTP libraries

    attr_accessor :host

    class HTTPError < RuntimeError
      attr_reader :response
      def initialize(response)
        @response = response
        super("Error performing HTTP request: #{response.status_code} #{response.reason}")
      end

      def body
        @body ||= begin
          MultiJson.load(response.body)
        rescue MultiJson::DecodeError
          response.body
        end
      end
    end

    def initialize(host, options = {})
      @host = host
      @http = HTTPClient.new
    end

    # Body can be a string or hash

    def get(path, args = {})
      parse_arguments_and_handle_response(args) do |query_string, body|
        http.get(url_for(path), :query => query_string, :body => body)
      end
    end

    def post(path, args = {})
      parse_arguments_and_handle_response(args) do |query_string, body|
        response = http.post(url_for(path), :query => query_string, :body => body)
      end
    end

    def put(path, args = {})
      parse_arguments_and_handle_response(args) do |query_string, body|
        response = http.put(url_for(path), :query => query_string, :body => body)
      end
    end

    def delete(path, args = {})
      parse_arguments_and_handle_response(args) do |query_string, body|
        response = http.delete(url_for(path), :query => query_string, :body => body)
      end
    end

    def head(path, args = {})
      query_string, _ = parse_arguments(args)
      http.head(url_for(path), :query => query_string)
    end

    private

    def parse_arguments_and_handle_response(args, &block)
      query_string, body = parse_arguments(args)
      parse_and_handle_response(
        block.call(query_string, body)
      )
    end

    def parse_and_handle_response(response)
      case response.status_code
      when 200..299
        MultiJson.load(response.body)
      else
        raise HTTPError.new(response)
      end
    end

    def parse_arguments(args)
      [args[:query_string], jsonify_body(args[:body])]
    end

    def jsonify_body(string_or_hash)
      return nil if string_or_hash.nil?
      case string_or_hash
      when Hash
        MultiJson.dump(string_or_hash)
      when String
        string_or_hash
      else
        raise ArgumentError.new("Unrecognised body class #{string_or_hash.class}")
      end
    end

    def http
      @http
    end

    def url_for(path)
      [host, path].join("/")
    end
  end
end
