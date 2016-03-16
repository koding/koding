globals = require 'globals'
globals.__remoteCache = {}

module.exports = RemoteExtensions =

  getInstance: (instanceId)     -> globals.__remoteCache[instanceId]

  setInstance: (data, instance) -> globals.__remoteCache[data._id] = instance

  initialize: (remote) ->

    (Object.keys remote.api).forEach (model) ->
      remote.api[model]::init = (data) ->
        super

        instance = RemoteExtensions.getInstance data._id

        unless instance
          RemoteExtensions.setInstance data, this
        else
          for own key of data when instance[key]?
            instance[key] = data[key]

    remote.api.JComputeStack = require './computestack'
    remote.api.JMachine      = require './machine'