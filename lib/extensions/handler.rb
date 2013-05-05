
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
			@socket 	= create_tcp_connection(uri)
			@websocket 	= generate_client_header(uri, session_id) #WebSocket::Handshake::Client.new(:url => create_websocket_uri(uri, session_id), :port => uri.port)
			@socket.write(@websocket.header)
			@socket.flush()
			# keep_alive!(options) if options[:keep_alive]
			
			return check_ws_handshake!
		end

		def close( code = 1005, reason = "", origin = :self )
			if !is(State::CLOSED) && !is(State::CLOSING)
				state State::CLOSING
				@socket.write("\xff\x00")
			end
			@socket.close() if origin == :peer
			state State::CLOSED
		end

		def send_data(data, type = :text)
			frame = outgoing_frame.new({
				:version 	=> @websocket.version,
				:data 		=> force_encoding(data.dup(), 'ASCII-8BIT'),
				:type 		=> type
			})
			@socket.write(frame.to_s)
			@socket.flush()
		end

		def receive_data
			frame = incoming_frame.new( :version => "hixie-76", :type => :text )
			data 		= force_encoding(read(2).to_s, "UTF-8").unpack("C*")
			# unpacked	= data.unpack("C*")
			DEBUG.info "===[ #{data} ]==="
			DEBUG.info "===[ opcode:#{data[0] & 0x0f} ]==="
			DEBUG.info "===[ length:#{data[1] & 0x7f} ]==="
			DEBUG.info "===[ #{read(data[1] & 0x7f)} ]==="
			# DEBUG.ingo unpacked
			return ""
			begin
				bytes 		= read(2).unpack('C*')
				opcode 		= bytes[0] & 0x0f
				plength 	= bytes[1] & 0x7f

				DEBUG.info [bytes, opcode, plength]
				if plength == 126
					bytes 		= read(2)
					plength 	= bytes.unpack('n')[0]
				elsif plength == 127
					bytes 		= read(8)
					(high, low) = bytes.unpack('NN')
					plength 	= high * (2 ** 32) + low
				end

				payload 	= read(plength)
				result 		= nil

				DEBUG.info "Payload: #{payload}"
				case opcode
					when OPCode::CONTINUATION	then result = "1::"
					when OPCode::TEXT 			then result = force_encoding(payload, 'UTF-8')
					when OPCode::BINARY 		then raise(LTSocketIO::Error::Handler::BinaryDataNotSupportedYet)
					when OPCode::CLOSE 			then close(1005, '', :peer)
					when OPCode::PING 			then raise(LTSocketIO::Error::Handler::PingDataNotSupportedYet)
					else result = ""
				end
				return result
			rescue EOFError
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
			protocol 	= uri.protocol == "https" ? "wss" : "ws"
			result_uri	= "#{protocol}://#{uri.host}/#{@resource}/1/websocket/#{session_id}"
			return result_uri
		end

		def create_tcp_connection(uri); TCPSocket.new(uri.host, uri.port) end

		def scan_uri(uri)
			uri_data = uri.scan(/(http[s]?:\/\/?)?([^:]+)(:([\d]+))?(\/([^\?]+))?(\?(.+))?/).first
			OpenStruct.new({
				:protocol	=> 	uri_data[0] 	|| 'http',
				:host		=> 	uri_data[1] 	|| 'localhost',
				:origin 	=>  (uri_data[0] || 'http') + "://" + (uri_data[1] || 'localhost') + (uri_data[3] ? ":#{uri_data[3]}" : ""),
				:port		=> 	(uri_data[3] 	|| 80).to_i,
				:path		=> 	uri_data[4] 	|| "",
				:params		=> 	uri_data[6]	 	|| ""
			})
		end

		def check_ws_handshake!;
			line 			= @socket.gets.chomp
			headers 		= read_header
			origin  		= (headers['sec-websocket-origin'] || '').downcase
			server_digest 	= @socket.read(16)
			
			raise(LTSocketIO::Error::Handler::BadResponse) 		unless line =~ /\AHTTP\/1.1 101 /n
			raise(LTSocketIO::Error::Handler::InvalidOrigin) 	unless origin == @websocket.uri.origin.downcase
			raise(LTSocketIO::Error::Handler::HandshakeFailed) 	unless server_digest == @websocket.digest
			state State::CONNECTED
			return true
		end

		def apply_mask(payload, mask_key)
			orig_bytes, new_bytes = payload.unpack('C*'), []
			orig_bytes.each_with_index {|b, i| new_bytes.push(b ^ mask_key[i % 4])}
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

		def generate_client_header(uri, session_id)
			hreader_string 	= "GET /socket.io/1/websocket/#{session_id} HTTP/1.1\r\n"
			headers 		= {
				"Upgrade" 		=> "WebSocket",
				"Connection"	=> "Upgrade",
				"Host" 			=> uri.host,
				"Origin" 		=> uri.origin
			}
			# generate keys
			key1, key2, key3 = WebsockerSecure.generate_key_1, WebsockerSecure.generate_key_1, WebsockerSecure.generate_key_3

			headers["Sec-WebSocket-Key1"] = key1
			headers["Sec-WebSocket-Key2"] = key2

			headers_compiled 	= (headers.map() {|key, value| "#{key}: #{value}\r\n" }).join("")
			headers_result 		= hreader_string + headers_compiled + "\r\n" + key3

			return OpenStruct.new({
				:header 	=> headers_result,
				:version 	=> 76,
				:uri 		=> uri,
				:digest 	=> WebsockerSecure.generate_extra_bytes(key1, key2, key3)
			})
		end

		def force_encoding(str, encoding); str.respond_to?(:force_encoding) ? str.force_encoding(encoding) : str end

		def read_header
			header_hash = {}
			while (line = gets())
				line = line.chomp()
				break if line.empty?
				raise(LTSocketIO::Error::Handler::BadResponse, "invalid request: #{line}") unless line =~ /\A(\S+): (.*)\z/n
				header_hash[$1] = $2
				header_hash[$1.downcase()] = $2
			end
			raise(LTSocketIO::Error::Handler::InvalidHeader, "Upgrade must be WebSocker, got %p" % header_hash['upgrade']) 		unless header_hash['upgrade'] =~ /\AWebSocket\z/i
			raise(LTSocketIO::Error::Handler::InvalidHeader, "Connection must be Upgrade, got %p" % header_hash['connection']) 	unless header_hash['connection'] =~ /\AUpgrade\z/i
			return header_hash
		end

		def incoming_frame; WebSocket::Frame::Incoming::Client end
		
		def outgoing_frame; WebSocket::Frame::Outgoing::Client end

		def read(num_bytes);
			str = @socket.read(num_bytes)
			if str && str.bytesize == num_bytes
				str
			else
				raise(EOFError)
			end
		end

		def write(data); @socket.write(data) end

		def gets(n = $/); @socket.gets end

		def flush; @socket.flush end

		def state(code); @state = code end

		def is(state_code); @state == state_code end

	end

end