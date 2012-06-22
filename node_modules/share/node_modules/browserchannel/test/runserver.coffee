# This file hosts a web server which exposes a bunch of browserchannel clients
# which respond in different ways to requests.

connect = require 'connect'
browserChannel = require('..').server
browserify = require 'browserify'

server = connect(
  connect.static "#{__dirname}/web"
  connect.logger()
  # Compile and host the tests. watch:true means the tests can be edited
  # without restarting the server.
  browserify entry:"#{__dirname}/browsersuite.coffee", watch:true, ignore:['nodeunit', '..']

  # When a client connects, send it a simple message saying its app version
  browserChannel base:'/notify', (session) ->
    session.send {appVersion: session.appVersion}

  # Echo back any JSON messages a client sends.
  browserChannel base:'/echo', (session) ->
    session.on 'message', (message) ->
      session.send message

  # Echo back any maps the client sends
  browserChannel base:'/echomap', (session) ->
    session.on 'map', (message) ->
      session.send message

  # This server aborts incoming sessions *immediately*.
  browserChannel base:'/dc1', (session) ->
    session.close()

  # This server aborts incoming sessions after sending
  browserChannel base:'/dc2', (session) ->
    process.nextTick ->
      session.close()

  browserChannel base:'/dc3', (session) ->
    setTimeout (-> session.close()), 100

  # Send a stop() message immediately
  browserChannel base:'/stop1', (session) ->
    session.stop()

  # Send a stop() message in a moment
  browserChannel base:'/stop2', (session) ->
    process.nextTick ->
      session.stop()
)

server.listen 4321
console.log 'Point your browser at http://localhost:4321/'
