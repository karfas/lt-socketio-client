require 'logger'
class DebugLogger < Logger
	def format_message(severity, timestamp, progname, msg)
		unless msg.nil?
			"#{msg.to_s.encode('UTF-8', :invalid => :replace, :replace => '')}\n"
		else
			"NULL LOG MESSAGE\n"
		end
	end
end