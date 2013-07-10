module YogaPants
  class Transport
    class Base
      def initialize(host, options = {})
        raise NotImplementedError
      end

      def get(path, args = {})
        raise NotImplementedError
      end

      def post(path, args = {})
        raise NotImplementedError
      end

      def put(path, args = {})
        raise NotImplementedError
      end

      def delete(path, args = {})
        raise NotImplementedError
      end

      def head(path, args = {})
        raise NotImplementedError
      end

      def reset
        raise NotImplementedError
      end
    end
  end
end
