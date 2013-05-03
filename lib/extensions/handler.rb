require 'rest_client'
require 'ostruct'
require 'websocket'

module LTSocketIO

	class Handler

		WEBSOCKET_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
		DEFAULT_CONFIG = {
			:keep_alive => true
		}

		def initialize(options = {})
			state State::CLOSED
			options 		= DEFAULT_CONFIG.update(options)
			@uri 			= scan_uri(options[:uri] || "localhost")
			@resource 		= options[:resource] || "socket.io"
			@handshaked 	= handshake!(options)
		end

		def handshake!(options)
			state State::CONNECTING
			handshake_url 	= create_uri(@uri.protocol, @uri.host, @uri.port)
			response 		= RestClient.get  handshake_url
			websocket_data	= [@uri] + response.split(':') << options
			connect(*websocket_data)
		end

		def connect(uri, session_id, heartbeat_timeout, connection_timeout, transports, options)
			@socket 	= TCPSocket.new uri.host, uri.port
			@websocket 	= WebSocket::Handshake::Client.new(:url => create_websocket_uri(uri, session_id), :port => uri.port)
			send_ws_handshake!
			keep_alive!(options) if options[:keep_alive]
			state State::CONNECTED
			return true
		end

		def close( code = 1005, reason = "", origin = :self )
			if !is(State::CLOSED) && !is(State::CLOSING)
				state State::CLOSING
				case @websocket.version
				when 75, 76
					write("\xff\x00")
				else
					payload = (code == 1005) ? "" : payload = [code].pack('n') + force_encoding(reason.dup(), 'ASCII-8BIT')
					send_data(payload, :close)
				end
			end
			@socket.close() if origin == :peer
			state State::CLOSED
		end

		def send_data(data, type = :text)
			frame = outgoing_frame.new({
				:version 	=> @websocket.version,
				:data 		=> data,
				:type 		=> type
			})
			@socket.write(frame)
		end

		def receive_data
			puts read(2)
			puts @state
			bytes 	= read(2).unpack('C*')
			opcode 	= bytes[0] & 0x0f
			mask 	= (bytes[1] & 0x80) != 0
			plength = bytes[1] & 0x7f

			case plength
			when 126
				bytes 		= read(2)
				plength		= bytes.unpack('n').first
			when 127
				bytes 		= read(8)
				(high, low) = bytes.unpack('NN')
				plength 	= high * ( 2 ** 32 ) + low
			end

			mask_key 	= mask ? read(4).unpack('C*') : nil
			payload 	= read(plength)
			payload 	= apply_mask(payload, mask_key) if mask

			case opcode
			when OPCode::TEXT
				puts "Text received"
				return force_encoding(payload, 'UTF-8')
			when OPCode::BINARY
				raise(WebSocket::Error, 'received binary data, which is not supported')
			when OPCode::CLOSE
				puts "Close received"
				close(1005, '', :peer) and return
			when OPCode::PING
				raise(LTSocketIO::Error::Handler::PingNotSupportedYet)
				return nil
			when OPCode::PONG
			else
				raise(LTSocketIO::Error::Handler::UnknownOpcode, 'received unknown opcode: %d' % opcode)
				return nil
			end
		end

		def handshaked?; @handshaked end

		def host; @uri.host end

		private

		def create_uri(protocol = "http", host = "localhost", port = "8080")
			@uri.protocol 	= protocol.to_s 	if @uri.protocol.nil?
			@uri.port 		= port.to_i 	if @uri.port.nil?
			@uri.path 		= host 			if @uri.path.nil?
			return "#{protocol}://#{host}:#{port}/#{@resource}/1/"
		end

		def create_websocket_uri(uri, session_id)
			protocol = uri.protocol == "https" ? "wss" : "ws"
			return "#{protocol}://#{uri.host}/#{@resource}/1/websocket/#{session_id}"
		end

		def scan_uri(uri)
			uri_data = uri.scan(/(http[s]?:\/\/?)?([^:]+)(:([\d]+))?(\/([^\?]+))?(\?(.+))?/).first
			OpenStruct.new({
				:protocol	=> 	uri_data[0] 	|| 'http',
				:host		=> 	uri_data[1] 	|| 'localhost',
				:port		=> 	(uri_data[3] 	|| 80).to_i,
				:path		=> 	uri_data[4] 	|| "",
				:params		=> 	uri_data[6]	 	|| ""
			})
		end

		def send_ws_handshake!;
			@socket.write @websocket.to_s
			line = @socket.gets($/).chomp()

			raise LTSocketIO::Error::Handler::BadResponse unless (line =~ /\AHTTP\/1.1 101 /n)

			flush
		end

		def apply_mask(payload, mask_key)
			# puts [payload, mask_key]
			orig_bytes = payload.unpack('C*')
			new_bytes = []
			orig_bytes.each_with_index() do |b, i|
				new_bytes.push(b ^ mask_key[i % 4])
			end
			new_bytes.pack('C*')
		end

		def keep_alive!(options)
			Thread.new do
				begin
					loop { send_data("2::"); sleep(10) }
				rescue IOError
					handshake!(options)
				end
			end
		end

		def incoming_frame; WebSocket::Frame::Incoming::Client end
		
		def outgoing_frame; WebSocket::Frame::Outgoing::Client end

		def read(num_bytes); @socket.read(num_bytes) end

		def write(data); @socket.write(data) end

		def gets(n = $/); @socket.gets end

		def flush; @socket.flush end

		def state(code); @state = code end

		def is(state_code); @state == state_code end

	end

end