require 'oj'

module LTSocketIO

	class Client

		VERSION = "0.1.0"

		def initialize(options = {})
			@handler 			= Handler.new options
			@watching_fiber		= create_watching_fiber
			@messages 			= []
			watch_for_socket_output
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

		def message(string)
			@handler.send_data("3:::#{string}")
		end

		def emit(event, hash)
			packet = { name: event, args: [hash] }
			@handler.send_data("5:::#{Oj.dump(packet, :mode => :compat)}")
		end

		def handshaked?; @handler.handshaked? end

		private

		def create_watching_fiber
			if @watching_fiber.nil? || !@watching_fiber.alive?
				@watching_fiber = Fiber.new do |data|
					@watching_fiber.yield if data.nil?

					puts "Data received"

				end
			end

			return @watching_fiber			
		end

	end

end