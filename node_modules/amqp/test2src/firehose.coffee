argv = require('optimist')
	.usage(''+
		'Test tracing/firehose message receipt.'+
		'\nA firehose message is generated both when a message is published and when it is consumed.'+
		'\nNOTE: this test will attempt to enable and then disable tracing for the vhost using rabbitmqctl.'
		)
	.demand('host').describe('host', 'Host').default('host', 'localhost')
	.demand('port').describe('port', 'Port').default('port', 5672)
	.demand('vhost').describe('vhost', 'Virtual Host').default('vhost', '/')
	.demand('login').describe('login', 'Login').default('login', 'guest')
	.demand('password').describe('password', 'Password')
	.argv

amqp = require '../amqp'
{exec} = require 'child_process'
assert = require 'assert'

message_s = ""
publish_message = ->
	message = hello:'world'
	message_s = JSON.stringify message
	default_exchange.publish test_queue_name, message
	console.log "test message published: #{JSON.stringify message} to queue: #{test_queue_name}"

count = 0
test_message = (message, headers, properties) ->
	console.log ""+
		"test message received: routing_key: '#{properties.routingKey}';"+
		" message: #{JSON.stringify message}"
	assert.equal message_s, JSON.stringify message, "incorrect message content or content_type"
	count++
	
firehose_message = (message, headers, properties) ->
	console.log ""+
		"firehose message received:  routing_key: '#{properties.routingKey}';"+
		" headers.routing_keys[0]: '#{headers.routing_keys[0]}';"+
		" message: #{JSON.stringify message}"
	assert.equal message_s, JSON.stringify message, "incorrect message content or content_type"
	assert.equal test_queue_name, headers.routing_keys[0], "routing key is not queue name in firehose message headers"
	count++

check_results = ->
	console.log "#{count} messages received"
	assert.equal 3, count, "wrong number of messages received"
	
	exec "rabbitmqctl trace_off -p #{argv.vhost}", (error, stdout, stderr) ->
		if error?
			console.log error
			process.exit 2
	
		process.exit 0
	
# initialize

default_exchange = {}
test_queue_name = 'test.firehose.test'
firehose_queue_name = 'test.firehose.firehose'

exec "rabbitmqctl trace_on -p #{argv.vhost}", (error, stdout, stderr) ->
	if error?
		console.log error
		process.exit 1

	{host, port, vhost, login, password} = argv

	options = 
		host:host
		port:port
		vhost:vhost
		login:login
		password:password

	amqp_connection = amqp.createConnection options

	amqp_connection.on 'ready', () -> 
			default_exchange = amqp_connection.exchange()

			amqp_connection.queue test_queue_name, (queue) ->
				queue.subscribe (message, headers, properties) -> 
					test_message message, headers, properties
				
				amqp_connection.queue firehose_queue_name, (queue) ->
					queue.bind "amq.rabbitmq.trace", "#", ->
						queue.subscribe (message, headers, properties) -> 
							firehose_message message, headers, properties
						
						setTimeout check_results, 1000
						publish_message()
