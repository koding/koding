{ EventEmitter } = require 'events'
chokidar         = require 'chokidar'
path             = require 'path'

app  = require('express')()
http = require('http').Server(app)
io   = require('socket.io')(http)
_    = require 'lodash'
SpecReporter       = require 'mocha/lib/reporters/spec'
ServerSocketRunner = require './serversocketrunner'

SOCKET_PORT = 1777
COMPILED_PATH = path.resolve __dirname, '../../../../website/a/p/p'
jsFiles = "#{COMPILED_PATH}/**/*.js"

mapping = require '../mapping.json'
preparedependencies = require '../util/preparedependencies'

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
_mainSockets = {}
_popupSockets = {}
_default = 'all'
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

  socket.on 'updateDefaultEmit', (type) ->
    _default = 'all'  unless type is 'main' or type is 'popup'

  socket.on 'result', (res) ->
    type = 'all'  unless _default is 'main' or _default is 'popup'
    emitTo type, res

  console.log 'connected', socket.id
  _sockets[socket.id] = socket

  socket.on 'disconnect', ->
    console.log 'disconnected', socket.id
    delete _sockets[socket.id]
    delete _mainSockets[socket.id]  if _mainSockets[socket.id]?
    delete _popupSockets[socket.id]  if _popupSockets[socket.id]?

  # register sockets as a main socket which listen popup's test results
  # or as a popup which run specific test file
  # or as all to tell results to every sockets
  socket.on 'registerAs', (socketType) ->
    switch socketType
      when 'main' then _mainSockets[socket.id] = socket
      when 'popup' then _popupSockets[socket.id] = socket
      else _sockets[socket.id] = socket

  socket.emit 'connection', socket.id


emitTo = (type, res) ->

  sockets = switch type
    when type is 'main' then _mainSockets
    when type is 'popup' then _popupSockets
    else _sockets

  Object.keys(sockets).forEach (id) ->
    socket = sockets[id]
    socket.emit 'result', res


# start server & listening.
http.listen SOCKET_PORT, -> console.log "Socket test runner started on port: #{SOCKET_PORT}"

createSession = (testName) ->

  return _.clone mapping[testName]

