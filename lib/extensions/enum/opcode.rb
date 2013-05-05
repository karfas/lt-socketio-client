module LTSocketIO

	class OPCode
		CONTINUATION 	= 0x00
		TEXT 			= 0x01
		BINARY 			= 0x02
		CLOSE 			= 0x08
		PING 			= 0x09
		PONG 			= 0x0f
	end

end