# This class defines an interface that must be implemented by stream handlers


module ThinConnector
  module Processor

    class MethodCalledOnInterface < StandardError; end

    class StreamHandler

      attr_accessor :stream, :run_thread

      def initialize(stream)
        @stream = stream
        @run_thread = nil
        @stopped = false
      end

      def start
        @stream.start{ |data| p data }
        run_thread = Thread.new do
          while not stopped

          end
        end
      end

      def stop
        stream.stop
        @stopped = true
        run_thread.join
      end

    end
  end
end
