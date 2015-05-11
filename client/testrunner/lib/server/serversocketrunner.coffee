{ EventEmitter } = require 'events'

module.exports = class ServerSocketRunner extends EventEmitter

  constructor: (socket) ->

    @socket = socket
    @bindSocketEvents()

  bindSocketEvents: ->

    @socket.on 'start', =>
      @emit 'start'

    @socket.on 'suite', (title) =>
      @emit 'suite', { title }

    @socket.on 'test end', (title) =>
      @emit 'test end', { title }

    @socket.on 'pass', (jsonified) =>
      test = JSON.parse jsonified
      test.slow = -> test.slowResult
      @emit 'pass', test

    @socket.on 'end', =>
      @emit 'end'

    @socket.on 'suite end', =>
      @emit 'suite end'

    @socket.on 'fail', (payload) =>

      { title, err, fullTitleResult } = JSON.parse payload

      test = { title }
      test.fullTitle = -> fullTitleResult
      test.err = err

      @emit 'fail', test, err


