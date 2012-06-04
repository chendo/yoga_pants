require 'httpclient'
require 'multi_json'

module YogaPants
  class Connection
    # This class is/will be an abstraction layer for the underlying
    # HTTP client.
    # TODO: Use https://github.com/rubiii/httpi so we don't have to deal
    # with interfacing with multiple HTTP libraries

    attr_accessor :host

    class HTTPError < RuntimeError; end

    def initialize(host, options = {})
      @host = host
      @http = HTTPClient.new
    end

    # Body can be a string or hash
    def get(path, query_string = {}, body = nil)
      body = jsonify_body(body)
      response = http.get(url_for(path), :query => query_string, :body => body)
      parse_and_handle_response(response)
    end

    def post(path, query_string = {}, body = nil)
      body = jsonify_body(body)
      response = http.post(url_for(path), :query => query_string, :body => body)
      parse_and_handle_response(response)
    end

    def put(path, query_string = {}, body = nil)
      body = jsonify_body(body)
      response = http.put(url_for(path), :query => query_string, :body => body)
      parse_and_handle_response(response)

    end

    def delete(path, query_string = {}, body = nil)
      body = jsonify_body(body)
      response = http.delete(url_for(path), :query => query_string, :body => body)
      parse_and_handle_response(response)
    end

    def head(path, query_string = {})
      http.head(url_for(path), :query => query_string)
    end

    private

    def parse_and_handle_response(response)
      case response.status_code
      when 200..299
        MultiJson.load(response.body)
      else
        pp response
        raise HTTPError.new("Error performing HTTP request: #{response.status_code} #{response.reason}")
      end
    end

    def jsonify_body(string_or_hash)
      return nil if string_or_hash.nil?
      case string_or_hash
      when Hash
        MultiJson.dump(string_or_hash)
      when String
        string_or_hash
      else
        raise HTTPError.new("Unrecognised body class #{string_or_hash.class}")
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
