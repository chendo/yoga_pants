$LOAD_PATH << File.dirname(__FILE__) + "/transport"
require 'uri'
module YogaPants
  class Transport
    class TransportError < RuntimeError
      attr_reader :response, :status_code
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

    class TransportNotFound < ArgumentError; end

    def self.transport_for(url, options = {}, &block)
      uri = URI(url)
      klass = @transports[uri.scheme]
      if klass.nil?
        raise TransportNotFound.new("No Transport found for scheme #{uri.scheme}")
      end
      klass.new(uri, options).tap do |transport|
        if block_given?
          block.call(transport)
        end
      end

    end

    def self.register_transport(klass, scheme)
      @transports ||= {}
      @transports[scheme] = klass
    end
  end
end
require 'base'
require 'http'
