module YogaPants
  class Connection
    # This class is/will be an abstraction layer for the underlying
    # HTTP client.
    # TODO: Use https://github.com/rubiii/httpi so we don't have to deal
    # with interfacing with multiple HTTP libraries

    attr_accessor :host, :options

    class HTTPError < RuntimeError
      attr_reader :response
      def initialize(message, response = nil)
        @response = response
        super(message)
      end

      def body
        return nil if response.nil?
        @body ||= begin
          JSON.load(response.body)
        rescue MultiJson::DecodeError
          response.body
        end
      end
    end

    def initialize(host, options = {})
      @host = host.chomp('/')
      @options = options || {}
      @http = HTTPClient.new

      default_timeout      = @options[:timeout] || 5
      http.connect_timeout = @options[:connect_timeout] || default_timeout
      http.send_timeout    = @options[:send_timeout] || default_timeout
      http.receive_timeout = @options[:receive_timeout] || default_timeout
    end

    # Body can be a string or hash

    def get(path, args = {})
      with_error_handling do
        parse_arguments_and_handle_response(args) do |query_string, body|
          http.get(url_for(path), :query => query_string, :body => body)
        end
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
      with_error_handling do
        query_string, _ = parse_arguments(args)
        http.head(url_for(path), :query => query_string)
      end
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
        JSON.load(response.body)
      else
        raise HTTPError.new("Error performing HTTP request: #{response.status_code} #{response.reason}", response)
      end
    end

    def parse_arguments(args)
      [args[:query_string], jsonify_body(args[:body])]
    end

    def with_error_handling(&block)
      block.call
    rescue HTTPError => e
      raise e
    rescue Errno::ECONNREFUSED
      raise HTTPError.new("Connection refused to #{host}")
    rescue HTTPClient::ConnectTimeoutError
      raise HTTPError.new("Connection timed out to #{host}")
    rescue HTTPClient::SendTimeoutError
      raise HTTPError.new("Request send timed out to #{host}")
    rescue HTTPClient::ReceiveTimeoutError
      raise HTTPError.new("Receive timed out from #{host}")
    rescue => e
      raise HTTPError.new("Unhandled exception within YogaPants::Connection: #{e} - #{e.message}").tap { |ex| ex.set_backtrace(e.backtrace) }
    end

    def jsonify_body(string_or_hash)
      return nil if string_or_hash.nil?
      case string_or_hash
      when Hash
        JSON.dump(string_or_hash)
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
      if path[0] == "/"
        "#{host}#{path}"
      else
        "#{host}/#{path}"
      end
    end
  end
end
