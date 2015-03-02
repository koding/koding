nick = require 'app/util/nick'
globals = require 'globals'
remote = require('app/remote').getInstance()


module.exports = UserEnvironmentDataProvider =

  fetch: (callback) ->

    remote.api.Sidebar.fetchEnvironment (err, data) =>
      return new KDNotificationView title : 'Couldn\'t fetch your VMs'  if err

      globals.userEnvironmentData = data
      callback data


  get: -> return globals.userEnvironmentData


  revive: ->

    empty = own: [], shared: [], collaboration: []
    data  = globals.userEnvironmentData or empty

    for section in [ data.own, data.shared, data.collaboration ]
      for obj in section
        obj.machine = remote.revive obj.machine
        for ws, i in obj.workspaces
          obj.workspaces[i] = remote.revive ws

      @isRevived = yes


  getMyMachines: -> return globals.userEnvironmentData.own


  getSharedMachines: ->

    { shared } = globals.userEnvironmentData

    return shared.concat @getCollaborationMachines()


  getCollaborationMachines: (callback) ->

    data = globals.userEnvironmentData.collaboration

    return data  unless callback

    callback data


  getAllMachines: ->

    { own, shared, collaboration } = globals.userEnvironmentData

    return own.concat shared.concat collaboration


  getMachineAndWorkspace: (options, callback) ->

    { machineLabel, workspaceSlug, username } = options

    isMe      = username is nick()
    data      = if isMe then @getMyMachines() else @getSharedMachines()
    machine   = null
    workspace = null

    for obj in data
      m = obj.machine

      if m.label is machineLabel
        machine = m

        for ws in obj.workspaces when ws.slug is workspaceSlug
          workspace = ws
          break

        break

    callback machine, workspace


  machineGetter_: (field, expectedValue, callback) ->

    for obj in @getAllMachines() when obj.machine[field] is expectedValue
      return callback obj.machine, obj.workspaces

    callback null, null


  getMachineByLabel: (machineLabel, callback) ->

    @machineGetter_ 'label', machineLabel, callback


  getMachineByUId: (uid, callback) ->

    @machineGetter_ 'uid', uid, callback


  getMachineAndWorkspaceByChannelId: (channelId, callback) ->

    @getCollaborationMachines (data) =>
      for obj in data
        for ws in obj.workspaces when ws.channelId is channelId
          return callback obj.machine, ws

    callback null, null


  validateCollaborationWorkspace: (machineLabel, workspaceSlug, channelId) ->

    @getAllMachines (obj) =>

      workspace = null

      if obj.machine.label is machineLabel
        for ws in obj.workspaces
          hasSameLabel     = ws.machineLabel is machineLabel
          hasSameSlug      = ws.slug is workspaceSlug
          hasSameChannelId = ws.channeId is channelId

          if sameLabel and sameSlug and sameChannelId
            workspace = ws

      return workspace
