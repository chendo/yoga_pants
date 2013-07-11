module YogaPants
  class Transport
    class Base
      def initialize(uri, options = {})
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

      def exists?(path, args = {})
        raise NotImplementedError
      end

      def reset
        raise NotImplementedError
      end

      protected

      def parse_arguments_and_handle_response(args, &block)
        query_string, body = parse_arguments(args)
        parse_and_handle_response(
          block.call(query_string, body)
        )
      end

      # This should return the unserialised result or raise an exception
      def parse_and_handle_response(response)
        raise NotImplementedError
      end

      def jsonify_body(string_or_hash)
        return nil if string_or_hash.nil?
        case string_or_hash
        when Hash
          JSON.dump(string_or_hash)
        when String
          string_or_hash
        else
          raise ArgumentError.new("Unrecognised body class #{string_or_hash.class}")
        end
      end

      def parse_arguments(args)
        [args[:query_string], jsonify_body(args[:body])]
      end
    end
  end
end
