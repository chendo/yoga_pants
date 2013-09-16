module YogaPants
  class Client
    # This class will handle:
    #   * connecting to ES nodes
    #   * failing over to nodes in a list
    #   * ES-specific error handling

    attr_accessor :hosts, :options, :active_host

    def initialize(hosts, options = {})
      @hosts       = [hosts].flatten.freeze # Accept 1 or more hosts
      @options     = options
      @max_retries = options[:max_retries] || 10
      @retries     = 0
      @mutex       = Mutex.new
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
      return [] if operations.empty?

      path = path.sub(%r{/(?:_bulk)?$}, '/_bulk')

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
      path = path.sub(%r{/?(?:_msearch)?$}, '/_msearch')

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
        connection.exists?(path)
      end
    end

    def reset
      connection.reset
    end

    class RequestError < RuntimeError; end

    class ElasticSearchError < RequestError
      attr_reader :elasticsearch_exception_name
      attr_reader :elasticsearch_exception_details

      def initialize(elasticsearch_error_message, original_exception)
        super(elasticsearch_error_message)
        set_backtrace(original_exception.backtrace)
        parse_and_set_elasticsearch_error_message(elasticsearch_error_message)
      end

      def parse_and_set_elasticsearch_error_message(message)
        if message =~ /(\w+)\[(.+)\]/m
          @elasticsearch_exception_name = $1
          @elasticsearch_exception_details = $2
        else
          @elasticsearch_exception_name = message
        end
      end

    end

    private

    def connection
      @mutex.synchronize do
        @connection ||= build_transport_for(active_host, options[:connection])
      end
    end

    def build_transport_for(host, options = {})
      options ||= {}
      Transport.transport_for(active_host, options) do |transport|
        if options[:init_hook].is_a?(Proc)
          options[:init_hook].call(transport)
        end
      end
    end

    def pick_next_host
      @mutex.synchronize do
        @active_host = @active_hosts.shift
        @connection = nil
        reset_hosts if active_host.nil?
      end
    end

    def with_error_handling(&block)
      block.call.tap do
        @retries = 0
      end
    rescue Transport::TransportError => e

      if @retries <= @max_retries
        @retries += 1
        pick_next_host
        retry
      elsif e.body.is_a?(Hash) && error_message = e.body['error']
        raise ElasticSearchError.new(error_message, e)
      else
        raise RequestError.new(e)
      end
    end
  end
end
