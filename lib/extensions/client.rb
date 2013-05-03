require 'oj'

module LTSocketIO

	class Client

		VERSION = "0.1.0"

		def initialize(options = {})
			@handler 			= Handler.new options
			@watching_fiber		= create_watching_fiber
			@listeners 			= {}
			connect! and watch_for_socket_output
		end

		public

		def on(event_name, &block); @listeners[event_name.to_sym] = block end

		def emit(event, hash); @handler.send_data("5:::#{json_stringify({ name: event, args: [hash] })}") end

		def message(string); @handler.send_data("3:::#{string}") end

		def send_heartbeat; @handler.send_data("2::") end

		def handshaked?; @handler.handshaked? end

		private

		def connect!; @handler.send_data "1::#{@handler.host}" end

		def create_watching_fiber
			if @watching_fiber.nil? || !@watching_fiber.alive?
				@watching_fiber = Fiber.new do |data|
					@watching_fiber.yield if data.nil?

					puts "Data received"

				end
			end

			return @watching_fiber			
		end

		def watch_for_socket_output
			main_thread = Thread.new do

				puts "Start watching for results"
				loop do
					puts "iteration"
					@watching_fiber.resume(@handler.receive_data)
					# sleep 0.1
				end

			end
		end


		def json_stringify(hash); Oj.dump(hash, :mode => :compat) end

		def json_parse(string); Oj.load(string, :mode => :compat) end

	end

end