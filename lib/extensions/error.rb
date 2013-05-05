module LTSocketIO

	class Error < RuntimeError

		class Client < ::LTSocketIO::Error

			class UnknownHost < ::LTSocketIO::Error::Client
				def message; :unknown_host end
			end

		end

		class Handler < ::LTSocketIO::Error

			class InvalifInput < ::LTSocketIO::Error::Handler
				def message; :invalid_input end
			end

			class InvalidOrigin < ::LTSocketIO::Error::Handler
				def message; :invalid_origin end
			end

			class InvalidHeader < ::LTSocketIO::Error::Handler
				def message; :invalid_header end
			end

			class HandshakeFailed < ::LTSocketIO::Error::Handler
				def message; :handshake_failed end
			end

			class PingNotSupportedYet < ::LTSocketIO::Error::Handler
				def message; :ping_not_supported_yet end
			end

			class BinaryDataNotSupportedYet < ::LTSocketIO::Error::Handler
				def message; :binary_data_not_supported_yet end
			end

			class BadRequest < ::LTSocketIO::Error::Handler
				def message; :bad_request end
			end

			class BadResponse < ::LTSocketIO::Error::Handler
				def message; :bad_response end
			end

			class UnknownOpcode < ::LTSocketIO::Error::Handler
				def message; :unknown_opcode end
			end

		end

	end

end