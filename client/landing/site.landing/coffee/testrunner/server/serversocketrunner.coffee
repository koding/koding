{ EventEmitter } = require 'events'
forwardEvents = require '../util/forwardevents'

module.exports = class ServerSocketRunner extends EventEmitter

  constructor: (socket) ->

    super

    @socket = socket
    @fakeSocket = new EventEmitter
    @bindSocketEvents()


  forwardFromSocket: (events, reducer) ->

    forwardEvents @fakeSocket, this, events, reducer


  bindSocketEvents: ->

    @socket.on 'result', (payload) =>
      events = JSON.parse payload
      events.map (e) => @fakeSocket.emit e...

    @forwardFromSocket ['start', 'end', 'suite end']

    # for 'suite', and 'test end' events
    # reporter waits for an object with a title property
    @forwardFromSocket ['suite', 'pending', 'test end'], (title) -> { title }

    @forwardFromSocket 'pass', (payload) ->
      test = JSON.parse payload
      test.slow = -> test.slowResult
      return test

    @forwardFromSocket 'fail', (payload) ->
      { title, err, fullTitleResult } = JSON.parse payload
      test = { title, err }
      test.fullTitle = -> fullTitleResult
      return [test, err]
