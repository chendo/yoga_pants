$LOAD_PATH << File.dirname(__FILE__) + "/transport"
module YogaPants
  class Transport
    class TransportError < RuntimeError; end
  end
end
require 'http'
