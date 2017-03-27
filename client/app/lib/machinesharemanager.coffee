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
      .on 'MachineShareActionTaken', (options) => @unset options.uid


  handleSharedMachineInvitation: (data) ->

    @set data.uid, { type: 'shared machine' }


  handleCollaborationInvitation: (data) ->

    { machineUId } = data

    type = 'collaboration'
    @set machineUId, { type }


  registerChannelEvent: (channelId, callback = kd.noop) ->

    { socialapi, groupsController } = kd.singletons

    socialapi.channel.byId { id: channelId }, (err, channel) ->
      if err
        kd.warn err
        return callback err

      group = groupsController.getCurrentGroup()
      socialapi.registerAndOpenChannel group, channel, (err, pubnubChannel) ->

        if err
          kd.warn err
          return callback err

        pubnubChannel?.channel?.once 'RemovedFromChannel', ->
          kd.singletons.computeController.storage.fetch()
