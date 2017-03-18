globals        = require 'globals'
REMOTE_CACHE   = {}
whoami = require 'app/util/whoami'

FORCE_CACHE_LIST = [
  'JStackTemplate'
]

module.exports = RemoteExtensions =


  initialize: (remote) ->

    remote.api.ComputeProvider = require './computeprovider'
    remote.api.JStackTemplate  = require './stacktemplate'
    remote.api.JComputeStack   = require './computestack'
    remote.api.JCredential     = require './credential'
    remote.api.JMachine        = require './machine'
    remote.api.JAccount        = require './account'
    remote.api.JGroup          = require './group'

    @injectCacheOnAPI remote


  injectCacheOnAPI: (remote) ->

    (Object.keys remote.api).forEach (model) ->

      original = remote.api[model]::init

      # overriding ::init on all `remote.api` which is getting called
      # inside of it's constructor.
      remote.api[model]::init = (data) ->

        original.call(this, data)

        # on each newlistener add we need to check and cache the instance
        # if update listener is added. which is used by kd.js to get data
        # update and redraw the ui components attached to it.
        @on 'newListener', (listener) =>
          if model not in FORCE_CACHE_LIST
            return  unless listener is 'update'
          # microemitter fires the `newListener` event before setting
          # the event itself so we need to wait for it until it's set.
          process.nextTick => RemoteExtensions.addInstance data._id, this

        # we need to try to cache all instances regardless it's listeners
        # RemoteExtensions will decide to keep or drop them away.
        RemoteExtensions.addInstance data._id, this

      # small helper to check instance ownership
      # if originId is provided in the model
      # please be aware this will return false all the time
      # if model doesn't have originId field in its schema
      remote.api[model]::isMine ?= -> @originId is whoami()._id


  getCache: globals._getRemoteCache = -> REMOTE_CACHE


  getInstances: (instanceId) -> @getCache()[instanceId] ? []


  hasInstances: (instanceId) -> (@getInstances instanceId).length > 0


  setInstances: (instanceId, instances) ->

    @getCache()[instanceId] = instances
    return instances


  addInstance: (instanceId, instance) ->

    if instance.constructor.name not in FORCE_CACHE_LIST
      return  unless instance._events?.update?

    instances  = @getCache()[instanceId]
    instances ?= []

    # check for existent instances, if listener added multiple times for
    # the same instance, it may end up having with duplicate instances in
    # the cache. ಠ_ಠ is used for id tagging the instances in microemitter
    # which helps us to compare instances to each other. ~GG
    for _instance in instances
      return  if _instance.ಠ_ಠ is instance.ಠ_ಠ

    instances.push instance

    @setInstances instanceId, instances


  updateInstance: (data) ->

    return  unless data

    { id: instanceId, change, timestamp } = data

    return  if (instances = @getInstances instanceId).length is 0

    # if there are instances which doesn't have update listeners anymore
    # we need to drop them from the cache to avoid memory leaks.
    instances = @setInstances instanceId, \
      instances.filter (instance) -> instance._events?.update?

    # updateInstance with provided change if it's not updated before
    # according to the provided timestamp (server time) ~GG
    instances

      .filter (instance) ->

        if instance.__lastUpdate?
          return instance.__lastUpdate < timestamp
        return yes

      .map (instance) ->

        instance.__lastUpdate = timestamp
        instance.emit 'updateInstance', change


  removeInstance: (data) ->

    return  unless data

    { id: instanceId } = data

    return  if (instances = @getInstances instanceId).length is 0

    instances.forEach (instance) -> instance.emit 'deleteInstance'

    @setInstances instanceId, null
