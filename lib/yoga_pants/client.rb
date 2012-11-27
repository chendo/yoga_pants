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

    attr_accessor :hosts, :options, :active_host

    def initialize(hosts, options = {})
      @hosts       = [hosts].flatten.freeze # Accept 1 or more hosts
      @options     = options
      @max_retries = options[:max_retries] || 10
      @retries     = 0
      reset_hosts
    end

    def reset_hosts
      @active_hosts = hosts.dup
      @active_host = @active_hosts.shift
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

    BULK_OPERATIONS_WITH_DATA = [:index, :create].freeze
    def bulk(path, operations, args = {})
      path.sub!(%r{/(?:_bulk)?$}, '/_bulk')

      with_error_handling do
        payload = StringIO.new

        operations.each do |action, metadata, data|
          payload << JSON.dump({action => metadata})
          payload << "\n"
          if BULK_OPERATIONS_WITH_DATA.include?(action.to_sym)
            payload << JSON.dump(data)
            payload << "\n"
          end
        end

        payload.rewind
        connection.post(path, :query_string => args, :body => payload.read)
      end
    end

    def multi_search(path, operations, args={})
      path = path.gsub(%r{/?(?:_msearch)?$}, '/_msearch')

      with_error_handling do
        payload = StringIO.new

        operations.each do |header, body|
          payload << JSON.dump(header) << "\n"
          payload << JSON.dump(body) << "\n"
        end

        payload.rewind
        connection.get(path, :query_string => args, :body => payload.read)
      end
    end

    def exists?(path, args = {})
      with_error_handling do
        begin
          if path.count("/") >= 3 # More than
            connection.get(path, args)
          else
            connection.head(path).status_code == 200
          end
        rescue Connection::HTTPError => e
          if e.status_code == 404
            false
          else
            raise e
          end
        end
      end
    end

    def reset
      connection.reset
    end

    private

    def connection
      @connection ||= Connection.new(active_host, options[:connection])
    end

    def pick_next_host
      @active_host = @active_hosts.shift
      @connection = nil
      reset_hosts if active_host.nil?
    end

    def with_error_handling(&block)
      block.call.tap do
        @retries = 0
      end
    rescue Connection::HTTPError => e

      if @retries <= @max_retries
        @retries += 1
        pick_next_host
        retry
      elsif e.body.is_a?(Hash) && error = e.body['error']
        raise RequestError.new("ElasticSearch Error: #{error}", e).tap { |ex| ex.set_backtrace(e.backtrace) }
      else
        raise RequestError.new(e.message, e).tap { |ex| ex.set_backtrace(e.backtrace) }
      end
    end
  end
end
