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

    def get(path, args = {})
      connection.get(path, args)
    end

    def post(path, args = {})
      connection.post(path, args)
    end

    def put(path, args = {})
      connection.put(path, args)
    end

    def delete(path, args = {})
      connection.delete(path, args)
    end

    def exists?(path, args = {})
      connection.head(path, args).status_code == 200
    end

    private

    def connection
      @connection ||= Connection.new(host, options[:connection])
    end
  end
end
