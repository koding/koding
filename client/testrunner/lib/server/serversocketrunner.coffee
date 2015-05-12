{ EventEmitter } = require 'events'
forwardEvents = require '../util/forwardevents'

module.exports = class ServerSocketRunner extends EventEmitter

  constructor: (socket) ->

    @socket = socket
    @bindSocketEvents()


  forwardFromSocket: (events, reducer) ->

    forwardEvents @socket, this, events, reducer


  bindSocketEvents: ->

    @forwardFromSocket ['start', 'end', 'suite end']

    # for 'suite', and 'test end' events
    # reporter waits for an object with a title property
    @forwardFromSocket ['suite', 'test end'], (title) -> { title }

    @forwardFromSocket 'pass', (payload) ->
      test = JSON.parse payload
      test.slow = -> test.slowResult
      return test

    @forwardFromSocket 'fail', (payload) ->
      { title, err, fullTitleResult } = JSON.parse payload
      test = { title, err }
      test.fullTitle = -> fullTitleResult
      return [test, err]


