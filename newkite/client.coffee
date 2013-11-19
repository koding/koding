WebSocket = require 'ws'
{EventEmitter} = require 'events'
{Scrubber, Store} = require 'koding-dnode-protocol'
noop = ->

class KiteClient extends EventEmitter
    constructor: (@remoteAddr='ws://localhost:4000/dnode')->
      @localStore = new Store
      @remoteStore = new Store

    connect: (callback=noop)->
      @ws = new WebSocket @remoteAddr
      self = this
      @ws.on 'open', ()->
        console.log "connected to ", self.remoteAddr
        self.emit 'connected'
        callback(self)

      @ws.on 'message', (data, flags)->
        # now we descrub message and call our callback function
        scrubbed = JSON.parse data
        scrubber = new Scrubber @localStore
        unscrubbed = scrubber.unscrub scrubbed
        callback = self.localStore.get(scrubbed.method)
        if callback
            callback.apply this, unscrubbed

    callRemote: (method, args, callback=noop)=>
      scrubber = new Scrubber @localStore
      # adding required stuff
      payload = {}
      payload.kite =
        name: "application"
        username: "devrim"
        id: "a8877ba5-9b18-420b-792a-e561316b3257"
        environment: 'development'
        region: 'localhost'
        version: "1" # <--- this should always be a string, dont ask me why, its not an integer
        hostname: "aybarss-MacBook-Air.local"
        publicIP:""
        port:"62428",
      payload.authentication =
        type:"kodingKey",
        key:"NPhFRpZPYuWA4kFA7Y0ewEIQy7qdgj3ij6tegRQ9sd2s-g2-Debdi20fStRiIM5Z"
      payload.withArgs = args
      payload.links = []

      scrubber.scrub [payload, callback], =>
          scrubbed = scrubber.toDnodeProtocol()
          scrubbed.method = method
          message = JSON.stringify scrubbed
          @ws.send message

    getKites: ()->
      @callRemote "getKites",
        "environment": "",
        "hostname": "",
        "id": "",
        "name": "mathworker",
        "region": "",
        "username": "devrim",
        "version": "",
        (err, kites)->
            console.log "getKites returned", err, kites


k = new KiteClient
#k.callRemote("getKites", {foo: 'bar'})
# k.getKites()
k.on 'connected', ()->
    console.log "connected...."
    k.getKites()
k.connect()