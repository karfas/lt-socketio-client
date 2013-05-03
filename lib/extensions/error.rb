module LTSocketIO

	class Error < RuntimeError

		class Client < ::LTSocketIO::Error

			class UnknownHost < ::LTSocketIO::Error::Client
				def message; :unknown_host end
			end

		end

		class Handler < ::LTSocketIO::Error

			class HandshakeFailed < ::LTSocketIO::Error::Handler
				def message; :handshake_failed end
			end

			class PingNotSupportedYet < ::LTSocketIO::Error::Handler
				def message; :ping_not_supported_yet end
			end

			class BinaryDataNotSupportedYet < ::LTSocketIO::Error::Handler
				def message; :binary_data_not_supported_yet end
			end

			class BadResponseReceived < ::LTSocketIO::Error::Handler
				def message; :bad_response_received end
			end

			class UnknownOpcode < ::LTSocketIO::Error::Handler
				def message; :unknown_opcode end
			end

		end

	end

end