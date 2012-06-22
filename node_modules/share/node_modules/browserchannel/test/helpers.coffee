# # Test Helpers
#
# This file contains some misc utility methods which the server & client tests use.

connect = require 'connect'
browserChannel = require('..').server

# This function provides an easy way for tests to create a new browserchannel server using
# connect().
#
# I'll create a new server in the setUp function of all the tests, but some
# tests will need to customise the options, so they can just create another server directly.
exports.createServer = (opts, method, callback) ->
  # Its possible to use the browserChannel middleware without specifying an options
  # object. This little createServer function will mirror that behaviour.
  if typeof opts == 'function'
    [method, callback] = [opts, method]
    # I want to match up with how its actually going to be used.
    bc = browserChannel method
  else
    bc = browserChannel opts, method
  
  # The server is created using connect middleware. I'll simulate other middleware in
  # the stack by adding a second handler which responds with 200, 'Other middleware' to
  # any request.
  server = connect bc, (req, res, next) ->
    # I might not actually need to specify the headers here... (If you don't, nodejs provides
    # some defaults).
    res.writeHead 200, 'OK', 'Content-Type': 'text/plain'
    res.end 'Other middleware'

  # Calling server.listen() without a port lets the OS pick a port for us. I don't
  # know why more testing frameworks don't do this by default.
  server.listen ->
    # Obviously, we need to know the port to be able to make requests from the server.
    # The callee could check this itself using the server object, but it'll always need
    # to know it, so its easier pulling the port out here.
    port = server.address().port
    callback server, port, bc


