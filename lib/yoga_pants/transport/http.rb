module YogaPants
  class Transport
    class HTTP < Base
      # This class is/will be an abstraction layer for the underlying
      # HTTP client.
      # TODO: Use https://github.com/rubiii/httpi so we don't have to deal
      # with interfacing with multiple HTTP libraries

      attr_accessor :host, :options

      class HTTPError < TransportError
        def initialize(message, response = nil)
          if response
            @status_code = response.status_code
            super(message + "\nBody: #{response.body}", response)
          else
            super(message)
          end
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

      def initialize(uri, options = {})
        @host = "http://#{uri.host}:#{uri.port}"
        @options = options || {}
        @http = HTTPClient.new
        @http.debug_dev = @options[:debug_io] if @options[:debug_io].respond_to?(:<<)

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
        with_error_handling do
          parse_arguments_and_handle_response(args) do |query_string, body|
            response = http.post(url_for(path), :query => query_string, :body => body)
          end
        end
      end

      def put(path, args = {})
        with_error_handling do
          parse_arguments_and_handle_response(args) do |query_string, body|
            response = http.put(url_for(path), :query => query_string, :body => body)
          end
        end
      end

      def delete(path, args = {})
        with_error_handling do
          parse_arguments_and_handle_response(args) do |query_string, body|
            response = http.delete(url_for(path), :query => query_string, :body => body)
          end
        end
      end

      def head(path, args = {})
        with_error_handling do
          query_string, _ = parse_arguments(args)
          http.head(url_for(path), :query => query_string)
        end
      end

      def exists?(path, args = {})
        head(path, args).status_code == 200
      end

      def reset
        http.reset_all
      end

      private

      def parse_and_handle_response(response)
        case response.status_code
        when 200..299
          JSON.load(response.body)
        else
          raise HTTPError.new("Error performing HTTP request: #{response.status_code} #{response.reason}", response)
        end
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

      def http
        @http
      end

      def url_for(path)
        if path[0..0] == "/"
          "#{host}#{path}"
        else
          "#{host}/#{path}"
        end
      end
    end

    Transport.register_transport(HTTP, 'http')
  end
end
