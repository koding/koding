globals = require 'globals'
globals.__remoteCache = {}

module.exports = RemoteExtensions =


  initialize: (remote) ->

    @injectCacheOnAPI remote

    remote.api.JComputeStack = require './computestack'
    remote.api.JMachine      = require './machine'


  injectCacheOnAPI: (remote) ->

    (Object.keys remote.api).forEach (model) ->

      remote.api[model]::init = (data) ->
        super

        RemoteExtensions.addInstance data._id, this


  getCache: -> globals.__remoteCache


  updateInstance: (instanceId) -> # , data) ->
  getInstances: (instanceId) -> @getCache()[instanceId] ? []


  hasInstances: (instanceId) -> (@getInstances instanceId).length > 0


  addInstance: (instanceId, instance) ->

    @getCache()[instanceId] ?= []
    @getCache()[instanceId].push instance


