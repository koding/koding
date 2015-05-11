module.exports = class RunnerSocketConnector

  constructor: (runner, socket) ->

    @_runner = runner
    @_socket = socket

    @connectRunnerToSocket()


  simulateRunnerStartEvent: ->

    @_runner.$events.start.forEach (handler) -> handler?()


  connectRunnerToSocket: ->

    @_runner.on 'start', =>
      @emitToSocket 'start'

    @_runner.on 'suite', (suite) =>
      @emitToSocket 'suite', suite.title

    @_runner.on 'suite end', =>
      @emitToSocket 'suite end'

    @_runner.on 'pending', (test) =>
      @emitToSocket 'pending', test.title

    @_runner.on 'test end', (test) =>
      @emitToSocket 'test end', test.title

    @_runner.on 'end', =>
      @emitToSocket 'end'

    @_runner.on 'pass', (test) =>
      { speed, title, duration } = test
      slowResult = test.slow()
      payload = JSON.stringify { speed, title, duration, slowResult }
      @emitToSocket 'pass', payload

    @_runner.on 'fail', (test, err) =>
      { title } = test
      fullTitleResult = test.fullTitle()
      payload = JSON.stringify { title, err, fullTitleResult }
      @emitToSocket 'fail', payload


  emitToSocket: (args...) -> @_socket.emit args...


