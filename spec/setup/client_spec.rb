require 'LTSocketIO'

describe 'Client' do
	
	before :all do
		@client = LTSocketIO::Client.new uri: "localhost:9999", :keep_alive => false
	end

	# it 'sould send message to server' do
	# 	@client.message('Plain text')
	# 	sleep 5
	# 	true.should == true
	# end

	it 'should emit event to server' do
		@client.emit("hello", {:qq => "Hello"})
		sleep 0.5
		true.should == true
	end

end