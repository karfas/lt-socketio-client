require 'extensions/debug_logger'

module LTSocketIO

	ROOT 			= File.expand_path(File.dirname(__FILE__))
	log_file 		= File.open("#{ROOT}/../log/debug.log", 'a')
	log_file.sync	= true
	DEBUG 			= ::DebugLogger.new log_file

	autoload :OPCode, 			"#{ROOT}/extensions/enum/opcode"
	autoload :State, 			"#{ROOT}/extensions/enum/state"
	autoload :Debug, 			"#{ROOT}/extensions/logger"
	autoload :Error, 			"#{ROOT}/extensions/error"
	autoload :Client, 			"#{ROOT}/extensions/client"
	autoload :Handler,			"#{ROOT}/extensions/handler"
	autoload :ResponseParser,	"#{ROOT}/extensions/parser"

end