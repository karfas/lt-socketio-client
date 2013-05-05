require 'digest/md5'

module LTSocketIO
	
	class WebsockerSecure

		def self.generate_key_1
			noise 		= ("\x21".."\x2f").to_a + ("\x3a".."\x7e").to_a
			spaces 		= 1 + rand(12)
			iterations 	= 1 + rand(12)
			max 		= 0xffffffff / spaces
			number 		= rand(max + 1)
			key 		= (number * spaces).to_s()

			iterations.times 	{ pos = rand(key.size + 1); key[pos...pos] = noise[rand(noise.size)] }
			spaces.times 		{ pos = 1 + rand(key.size - 1); key[pos...pos] = " " }
			key
		end

		def self.generate_key_3
			[rand(0x100000000)].pack('N') + [rand(0x100000000)].pack('N')
		end

		def self.generate_extra_bytes(key1, key2, key3)
			bytes1 = websocket_key_to_bytes(key1)
			bytes2 = websocket_key_to_bytes(key2)
			Digest::MD5.digest(bytes1 + bytes2 + key3)
		end

		private

		def self.websocket_key_to_bytes(key)
			num = key.gsub(/[^\d]/n, '').to_i() / key.scan(/ /).size
			[num].pack('N')
		end

	end

end