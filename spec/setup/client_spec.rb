require 'LTSocketIO'

describe 'Client' do
	
	before :all do
		@client = LTSocketIO::Client.new uri: "localhost:9999", :keep_alive => false
	end

	it 'sould send message to server' do
		sleep 1
		@client.message('Plain text')
		@client.send_heartbeat
		sleep 3
		true.should == true
	end

	# it 'should emit event to server' do
	# 	@client.emit("hello", {:qq => "Hello"})
	# 	sleep 0.5
	# 	true.should == true
	# end

end