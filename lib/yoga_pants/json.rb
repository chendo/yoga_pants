require 'multi_json'

# FIXME: This whole thing is cancer. tire uses multi_json 1.0.3 which
# uses decode/encode.

module YogaPants
  class JSON
    def self.load(*args)
      if MultiJson.respond_to?(:decode)
        MultiJson.decode(*args)
      else
        MultiJson.load(*args)
      end
    end

    def self.dump(*args)
      if MultiJson.respond_to?(:encode)
        MultiJson.encode(*args)
      else
        MultiJson.dump(*args)
      end
    end

  end
end
