browserChannel = require('..').server
connect = require 'connect'

clients = []

server = connect(
	connect.static "#{__dirname}/public"
	browserChannel (client) ->
		console.log "Client #{client.id} connected"

		clients.push client

		client.on 'map', (data) ->
			console.log "#{client.id} sent #{JSON.stringify data}"
			# broadcast to all other clients
			c.send data for c in clients when c != client

		client.on 'close', (reason) ->
			console.log "Client #{client.id} disconnected (#{reason})"
			# Remove the client from the client list
			clients = (c for c in clients when c != client)

).listen(4321)

console.log 'Echo server listening on localhost:4321'
