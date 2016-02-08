kd           = require 'kd'
whoami       = require 'app/util/whoami'
dataProvider = require './userenvironmentdataprovider'

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

    @set data.uid, type: 'shared machine'


  handleCollaborationInvitation: (data) ->

    {machineUId, workspaceId} = data

    type = 'collaboration'
    @set machineUId, {type, workspaceId}


  registerChannelEvent: (channelId) ->

    { socialapi, groupsController } = kd.singletons

    socialapi.channel.byId { id: channelId }, (err, channel) ->
      return callback err   if err

      group = groupsController.getCurrentGroup()
      socialapi.registerAndOpenChannel group, channel, (err, pubnubChannel) ->

        return callback err   if err

        pubnubChannel.channel.once 'RemovedFromChannel', ->
          dataProvider.fetch ->
            kd.singletons.mainView.activitySidebar.redrawMachineList()
