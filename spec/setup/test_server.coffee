io = require('socket.io').listen(9999)

io.sockets.on "connection", (socket)->

	socket.on "message", (msg)->
		console.log "Received message: #{msg}"

	socket.on "hello", (data)->
		console.log data
		socket.emit("response", { hello: "there" })
