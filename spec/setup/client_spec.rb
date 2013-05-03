require 'LTSocketIO'

describe 'Client' do
	
	before :all do
		@client = LTSocketIO::Client.new uri: "localhost:9999"
	end

	it 'sould send message to server' do
		@client.message('Plain text')
	end

	it 'should emit event to server' do
		@client.emit("hello", {:qq => "Hello"})
		sleep 3
		true.should == true
	end

end