{ EventEmitter } = require 'events'
chokidar         = require 'chokidar'
path             = require 'path'

app  = require('express')()
http = require('http').Server(app)
io   = require('socket.io')(http)

SpecReporter       = require 'mocha/lib/reporters/spec'
ServerSocketRunner = require './serversocketrunner'

SOCKET_PORT = 1777
COMPILED_PATH = path.resolve __dirname, '../../../../website/a/p/p'
jsFiles = "#{COMPILED_PATH}/**/*.js"

# For now it's a simple event emitter but it will evolve soon enough. Keeping
# it seperate enables us to make stuff like `dispatcher.emit 'change'` to run
# tests on every connected socket.
dispatcher = new EventEmitter

# start watching compiled js files, whenever something changes over there
# dispatcher's gonna dispatch a change event.
watcher = chokidar.watch jsFiles, { persistent: yes }
watcher.on 'change', -> dispatcher.emit 'change'

# connected socket registry.
_sockets = {}

# whenever a change event occurs send a reload event to all connected sockets
# to re-run the tests.
dispatcher.on 'change', ->
  Object.keys(_sockets).forEach (id) -> _sockets[id].emit 'reload'

# every socket connection will be wrapped by a `ServerSocketRunner` instance
# then the `SpecReporter` (for now, it can be extended with some CLI options
# later on) will use that runner instance to print the result coming from
# socket to the terminal.
io.on 'connection', (socket) ->

  # create a runner for this connection
  runner = new ServerSocketRunner socket

  # connect socket runner to spec reporter
  new SpecReporter runner

  console.log 'connected', socket.id
  _sockets[socket.id] = socket

  socket.on 'disconnect', ->
    console.log 'disconnected', socket.id
    delete _sockets[socket.id]

# start server & listening.
http.listen SOCKET_PORT, -> console.log "Socket test runner started on port: #{SOCKET_PORT}"
