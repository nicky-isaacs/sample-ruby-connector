require 'eventmachine'
require 'em-http-request'
require 'json'
require 'yajl'
require 'byebug'
require_relative './stream_helper.rb'

module ThinConnector
  module Stream

    class GNIPStream < Stream::Base
      include ThinConnector::Stream::StreamHelper

      EventMachine.threadpool_size = 3

      attr_accessor :headers, :options, :url, :string_buffer
      attr_reader :username, :password

      def initialize(url=nil, headers={})
        @logger = ThinConnector::Logger.new
        @url = url

        # testing
        @url ||= 'https://stream.gnip.com:443/accounts/isaacs/publishers/twitter/streams/track/prod.json'
        @headers = headers.merge({ accept: 'application/json'})
        @stream_reconnect_time = 1
        @string_buffer=''

        @parser = Yajl::Parser.new(:symbolize_keys => true)
        @parser.on_parse_complete = method(:object_parsed)
      end

      def start
        if block_given?
          @processor = Proc.new
        else
          @processor = Proc.new{ |data| puts data }
        end
        connect_stream
      end

      def stop
        @stopped = true
      end

      def on_message(&block)
        @on_message = block
      end

      def on_connection_close(&block)
        @on_connection_close = block
      end

      private

      def connect_stream
        EM.run do
          http = EM::HttpRequest.new(@url, keep_alive: true,  inactivity_timeout: 2**16, connection_timeout: 100000).get(head: @headers)
          http.stream { |chunk| process_chunk(chunk) }
          http.callback {
            handle_connection_close(http)
            reconnect
          }
          http.errback {
            handle_error(http)
            reconnect
          }

          EM.add_periodic_timer(3) do
            if stopped?
              EM.stop_event_loop
            end
          end
        end
      end

      def reconnect
        @logger.error 'Reconnecting'
        return if stopped?
        sleep @stream_reconnect_time
        bump_reconnect_time
        @logger.debug "Reconnect time bumped to: #{@stream_reconnect_time}"
        reset_reconnect_time if connect_stream
      end

      def process_chunk(chunk)
        @parser << chunk
      end

      def handle_error(http_connection)
        @logger.warn('Error with http connection ' + http_connection.inspect)
        reconnect
      end

      def handle_connection_close(http_connection)
        @logger.warn "HTTP connection closed #{http_connection.inspect}"
        reconnect
      end

      def stopped?
        @stopped
      end

      def object_parsed(obj)
        @processor.call obj
      end
    end
  end
end
