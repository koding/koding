forwardEvents        = require './util/forwardevents'
BufferedEventEmitter = require './util/bufferedeventemitter'

module.exports = class RunnerSocketConnector

  constructor: (runner, socket) ->

    @_runner = runner
    @_socket = socket

    @_bufferedEmitter = new BufferedEventEmitter

    @connectRunnerToSocket()


  simulateRunnerStartEvent: ->

    @_runner.$events.start.forEach (handler) -> handler?()


  forwardToSocket: (name, reducer) ->

    forwardEvents @_runner, @_bufferedEmitter, name, reducer

    # forward reduced events from buffer to socket without reducing again.
    forwardEvents @_bufferedEmitter, @_socket, name


  sendResult: -> @_socket.emit 'result', @_bufferedEmitter.toJSON()


  connectRunnerToSocket: ->

    @forwardToSocket ['start', 'end', 'suite end']

    @forwardToSocket ['suite', 'pending', 'test end'], (test) -> test.title

    @forwardToSocket 'pass', (test) ->
      { speed, title, duration } = test
      slowResult = test.slow()
      return JSON.stringify { speed, title, duration, slowResult }

    @forwardToSocket 'fail', (test, err) ->
      { title } = test
      fullTitleResult = test.fullTitle()
      return JSON.stringify { title, err, fullTitleResult }
