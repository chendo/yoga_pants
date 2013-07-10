$LOAD_PATH << File.dirname(__FILE__) + "/transport"
require 'uri'
module YogaPants
  class Transport
    class TransportError < RuntimeError; end
    class TransportNotFound < ArgumentError; end

    def self.transport_for(url, options = {})
      uri = URI(url)
      klass = @transports[uri.scheme]
      if klass.nil?
        raise TransportNotFound.new("No Transport found for scheme #{uri.scheme}")
      end
      klass.new(uri, options)
    end

    def self.register_transport(klass, scheme)
      @transports ||= {}
      @transports[scheme] = klass
    end
  end
end
require 'base'
require 'http'
