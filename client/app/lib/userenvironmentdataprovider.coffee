kd = require 'kd'
nick = require 'app/util/nick'
globals = require 'globals'
remote = require('app/remote').getInstance()
Machine = require 'app/providers/machine'


module.exports = UserEnvironmentDataProvider =


  fetch: (callback) ->

    remote.api.Sidebar.fetchEnvironment (err, data) =>
      return new KDNotificationView title : 'Couldn\'t fetch your VMs'  if err

      data = @setDefaults_ data
      globals.userEnvironmentData = data
      callback data


  get: ->
    return @setDefaults_ globals.userEnvironmentData


  setDefaults_: (data = {}) ->

    data.own           or= []
    data.shared        or= []
    data.collaboration or= []

    return data


  hasData: ->

    data = @get()

    return  no unless data

    hasOwn    = data.own.length > 0
    hasShared = data.shared.length > 0
    hasCollab = data.collaboration.length > 0

    return hasOwn or hasShared or hasCollab


  revive: ->

    return no  unless @hasData()

    for key, section of @get()
      for obj in section
        obj.machine = remote.revive obj.machine
        for ws, i in obj.workspaces
          obj.workspaces[i] = remote.revive ws


  getMyMachines: -> return @get().own


  getSharedMachines: ->

    { shared } = @get()

    return shared.concat @getCollaborationMachines()


  getCollaborationMachines: ->

    return @get().collaboration


  getAllMachines: ->

    { own, shared, collaboration } = @get()

    return own.concat shared.concat collaboration


  fetchMachine: (labelOrUId, callback) ->

    @fetchMachineByLabel labelOrUId, (machine) =>
      return  callback new Machine { machine }  if machine

      @fetchMachineByUId labelOrUId, (machine) =>
        machine = if machine then new Machine { machine } else null

        callback machine


  fetchWorkspaceByMachineUId: (options, callback) ->

    { machineUId, workspaceSlug } = options

    data      = @getAllMachines()
    workspace = null

    for obj in data
      m = obj.machine

      if m.uid is machineUId
        for ws in obj.workspaces when ws.slug is workspaceSlug
          workspace = ws
          break

        break

    callback workspace


  machineFetcher_: (field, expectedValue, callback) ->

    m = null
    w = null

    for obj in @getAllMachines()
      if obj.machine[field] is expectedValue
        m = obj.machine
        w = obj.workspaces

        break

    callback m, w


  fetchMachineBySlug: (slug, callback) ->

    @machineFetcher_ 'slug', slug, callback


  fetchMachineByLabel: (label, callback) ->

    @machineFetcher_ 'label', label, callback


  fetchMachineByUId: (uid, callback) ->

    @machineFetcher_ 'uid', uid, callback


  fetchMachineAndWorkspaceByChannelId: (channelId, callback) ->

    machine   = null
    workspace = null
    data      = @getAllMachines()

    for obj in data
      for ws in obj.workspaces
        if ws.channelId is channelId
          machine   = obj.machine
          workspace = ws

    callback machine, workspace


  validateCollaborationWorkspace: (machineLabel, workspaceSlug, channelId) ->

    data      = @getAllMachines()
    workspace = null

    for obj in data when obj.machine.label is machineLabel
      for ws in obj.workspaces
        hasSameLabel     = ws.machineLabel is machineLabel
        hasSameSlug      = ws.slug is workspaceSlug
        hasSameChannelId = ws.channeId is channelId

        if hasSameLabel and hasSameSlug and hasSameChannelId
          workspace = ws
          break

    return workspace


  getIDEFromUId: (uid) ->

    { IDE } = kd.singletons.appManager.appControllers

    return null  unless IDE

    for i in IDE.instances when i.mountedMachineUId
      instance = i
      break

    return instance
