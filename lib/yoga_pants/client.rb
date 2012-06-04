require_relative "connection"
module YogaPants
  class Client
    # This class will handle:
    #   * connecting to ES nodes
    #   * failing over to nodes in a list
    #   * ES-specific error handling

    attr_accessor :host, :options

    def initialize(host, options = {})
      @host = host
      @options = options
    end

    def get(path, query_string = {}, body = nil)
      connection.get(path, query_string, body)
    end

    def post(path, query_string = {}, body = nil)
      connection.post(path, query_string, body)
    end

    def put(path, query_string = {}, body = nil)
      connection.put(path, query_string, body)
    end

    def delete(path, query_string = {}, body = nil)
      connection.delete(path, query_string, body)
    end

    def exists?(path, query_string = {})
      connection.head(path, query_string).status_code == 200
    end

    private

    def connection
      @connection ||= Connection.new(host, options[:connection])
    end
  end
end
