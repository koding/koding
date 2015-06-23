kd = require 'kd'

module.exports = class MachineShareManager extends kd.Object

  constructor: (options = {}, data) ->

    super options, data

    @registry = {}
    @callbacks = {}

    @bindEvents()


  get: (uid) ->  @registry[uid]


  set: (uid, data) ->

    @registry[uid] = data

    @callbacks[uid]?.forEach (callback) -> callback data


  unset: (uid) ->

    @registry[uid] = null


  subscribe: (uid, callback) ->

    (@callbacks[uid] ?= []).push callback


  unsubscribe: (uid, callback) ->

    index = @callbacks[uid]?.indexOf callback
    @callbacks[uid].splice index, 1  if index > -1


  bindEvents: ->

    kd.singletons.notificationController

      .on 'SharedMachineInvitation', @bound 'handleSharedMachineInvitation'
      .on 'CollaborationInvitation', @bound 'handleCollaborationInvitation'


  handleSharedMachineInvitation: (data) ->

    @set data.uid, type: 'shared machine'


  handleCollaborationInvitation: (data) ->

    {machineUId, workspaceId} = data

    type = 'collaboration'
    @set machineUId, {type, workspaceId}
