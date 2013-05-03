module LTSocketIO

	ROOT 		= File.expand_path(File.dirname(__FILE__))

	autoload :OPCode, 			"#{ROOT}/extensions/opcode"
	autoload :State, 			"#{ROOT}/extensions/state"
	autoload :Error, 			"#{ROOT}/extensions/error"
	autoload :Client, 			"#{ROOT}/extensions/client"
	autoload :Handler,			"#{ROOT}/extensions/handler"
	autoload :ResponseParser,	"#{ROOT}/extensions/parser"

end