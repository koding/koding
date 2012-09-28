usage_text =
'
Test federated multi-hop message receipt.
\n
\n* Probably you want to do this on a fresh rabbitmq install...
\n
\nTo enable this test:
\n1. Create a virtual host named "reflector" and provide access
\n2. Bring down the rabbit
\n3. Enable the federation plugin
\n4. Include this federation configuration as or in your rabbitmq.config file and bring up the rabbit:
\n[
\n  {rabbitmq_federation, [ 
\n    {exchanges, [
\n      [
\n        {exchange, "test.federation"},
\n        {virtual_host, "reflector"},
\n        {type, "topic"},
\n        {upstream_set, "root.set"}
\n      ],
\n      [
\n        {exchange, "test.federation"},
\n        {virtual_host, "/"},
\n        {type, "topic"},
\n        {upstream_set, "reflector.set"}
\n      ]
\n    ]},
\n    {upstream_sets, [
\n      {"reflector.set", [
\n        [
\n          {connection, "reflector.connection"},
\n          {max_hops, 2}
\n        ]
\n      ]},
\n      {"root.set", [
\n        [
\n          {connection, "root.connection"},
\n          {max_hops, 2}
\n        ]
\n      ]}
\n    ]},
\n    {connections, [
\n      {"reflector.connection", [ 
\n        {host, "localhost"},
\n        {virtual_host, "reflector"},
\n        {username, "guest"},
\n        {password, "guest"}
\n      ]}, 
\n      {"root.connection", [ 
\n        {host, "localhost"},
\n        {virtual_host, "/"},
\n        {username, "guest"},
\n        {password, "guest"}
\n      ]}
\n    ]},
\n    {local_username, "guest"},
\n    {local_password, "guest"}
\n  ]}
\n].
'
argv = require('optimist')
	.usage(usage_text)
	.demand('host').describe('host', 'Host').default('host', 'localhost')
	.demand('port').describe('port', 'Port').default('port', 5672)
	.demand('vhost').describe('vhost', 'Virtual Host').default('vhost', '/')
	.demand('login').describe('login', 'Login').default('login', 'guest')
	.demand('password').describe('password', 'Password')
	.argv

amqp = require '../amqp'
assert = require 'assert'

message_s = ""
publish_message = ->
	message = hello:'world'
	message_s = JSON.stringify message
	test_exchange.publish 'whatever', message
	console.log "test message published: #{JSON.stringify message} to exchange: #{test_exchange_name}"

count = 0
test_message = (message, headers, properties) ->
	console.log ""+
		"test message received:  message: #{JSON.stringify message}"+
		"\n  headers: #{JSON.stringify headers, undefined, 4}"
	assert.equal message_s, JSON.stringify message, "incorrect message content or content_type"
	assert.equal 'reflector', headers["x-received-from"][0]["virtual_host"], "missing or mismatched virtual host name" if count is 1
	count++

check_results = ->
	console.log "#{count} messages received"
	assert.equal 2, count, "wrong number of messages received"
	process.exit 0
	
# initialize

test_exchange = {}
test_queue_name = test_exchange_name = 'test.federation'
{host, port, vhost, login, password} = argv

options = 
	host:host
	port:port
	vhost:vhost
	login:login
	password:password

amqp_connection = amqp.createConnection options

amqp_connection.on 'ready', () -> 
	amqp_connection.exchange test_exchange_name, passive:true, (exchange) ->
		test_exchange = exchange

		amqp_connection.queue test_queue_name, (queue) ->
			queue.bind test_exchange, '#', ->
				queue.subscribe (message, headers, properties) -> 
					test_message message, headers, properties
						
				setTimeout check_results, 1000
				publish_message()
