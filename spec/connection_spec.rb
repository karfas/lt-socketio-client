require 'LTSocketIO'

describe 'Connection' do

	it 'should handshake with socket' do
		connection = LTSocketIO::Handler.new uri: "localhost:9999"
		connection.handshaked?.should == true
	end

	it 'should handshake using client' do
		connection = LTSocketIO::Client.new uri: "localhost:9999"
		connection.handshaked?.should == true
	end

end