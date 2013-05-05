require 'oj'
require 'fiber'

module LTSocketIO

	class Client

		VERSION = "0.1.0"

		def initialize(options = {})
			@handler = Handler.new(options)
			connect!
			watch_for_socket_output!
		end

		public

		def on(event_name, &block); @listeners[event_name.to_sym] = block end

		def emit(event, hash); @handler.send_data("5:::#{json_stringify({ name: event, args: [hash] })}") end

		def message(string); @handler.send_data("3:::#{string}") end

		def send_heartbeat; @handler.send_data("2::") end

		def handshaked?; @handler.handshaked? end

		private

		def connect!;
			DEBUG.info "Connecting! #{@handler.host}"
			@handler.send_data "1::#{@handler.host}"
		end

		def create_watching_fiber
			if @watching_fiber.nil? || !@watching_fiber.alive?
				puts "Creating fiber"
				@watching_fiber = Fiber.new do |data|

					DEBUG.info "Data received"
					Fiber.yield

				end
			end

			return @watching_fiber	
		end

		def watch_for_socket_output!
			@thread = Thread.new() do
				while data = @handler.receive_data
					DEBUG.info data.is_a? String
					DEBUG.info ResponseParser.parse(data)
				end
			end
			@thread
		end


		def json_stringify(hash); Oj.dump(hash, :mode => :compat) end

		def json_parse(string); Oj.load(string, :mode => :compat) end

	end

end