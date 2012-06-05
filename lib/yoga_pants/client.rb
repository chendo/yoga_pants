require_relative "connection"
module YogaPants
  class Client
    # This class will handle:
    #   * connecting to ES nodes
    #   * failing over to nodes in a list
    #   * ES-specific error handling

    class RequestError < RuntimeError
      attr_reader :http_error

      def initialize(message, http_error = nil)
        @http_error = nil
        super(message)
      end
    end

    attr_accessor :host, :options

    def initialize(host, options = {})
      @host = host
      @options = options
    end

    def get(path, args = {})
      with_error_handling do
        connection.get(path, args)
      end
    end

    def post(path, args = {})
      with_error_handling do
        connection.post(path, args)
      end
    end

    def put(path, args = {})
      with_error_handling do
        connection.put(path, args)
      end
    end

    def delete(path, args = {})
      with_error_handling do
        connection.delete(path, args)
      end
    end

    def exists?(path, args = {})
      with_error_handling do
        connection.head(path, args).status_code == 200
      end
    end

    private

    def connection
      @connection ||= Connection.new(host, options[:connection])
    end

    def with_error_handling(&block)
      block.call
    rescue Connection::HTTPError => e
      if e.body.is_a?(Hash) && error = e.body['error']
        raise RequestError.new("ElasticSearch Error: #{error}", e).tap { |ex| ex.set_backtrace(e.backtrace) }
      else
        raise RequestError.new(e.message, e).tap { |ex| ex.set_backtrace(e.backtrace) }
      end
    end
  end
end
