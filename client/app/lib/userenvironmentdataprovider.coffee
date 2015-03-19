kd = require 'kd'
nick = require 'app/util/nick'
globals = require 'globals'
remote = require('app/remote').getInstance()
Machine = require 'app/providers/machine'
sinkrow = require 'sinkrow'

KDNotificationView = kd.NotificationView


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


  fetchMachine: (identifier, callback) ->

    @fetchMachineBySlug identifier, (machine) =>
      return callback new Machine { machine }  if machine

      @fetchMachineByLabel identifier, (machine) =>
        return  callback new Machine { machine }  if machine

        @fetchMachineByUId identifier, (machine) =>
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


  fetchMachineById: (id, callback) ->

    @machineFetcher_ '_id', id, callback


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


  findWorkspace: (machineLabel, workspaceSlug, channelId) ->

    for item in @getAllMachines()

      {machine, workspaces} = item

      slugMatches  = machineLabel is machine.slug
      labelMatches = machineLabel is machine.label

      continue  unless slugMatches or labelMatches

      for workspace in workspaces
        hasSameLabel     = workspace.machineLabel is machine.label
        hasSameSlug      = workspace.slug is workspaceSlug
        hasSameChannelId = if channelId then workspace.channelId is channelId else yes

        if hasSameLabel and hasSameSlug and hasSameChannelId
          return workspace


  getIDEFromUId: (uid) ->

    { IDE } = kd.singletons.appManager.appControllers

    return null  unless IDE

    for i in IDE.instances when i.mountedMachineUId
      instance = i
      break

    return instance


  createDefaultWorkspace: (machine, callback) ->

    remote.api.JWorkspace.createDefault machine.uid, (err, workspace) ->

      if err
        console.error "User Environment  Data Provider:", err

      callback err, workspace


  ensureDefaultWorkspace: (callback) ->

    data = @get()

    queue = @getMyMachines().concat @getSharedMachines()

      .map ({machine, workspaces}) =>

        =>

          kd.utils.defer =>

            for workspace in workspaces when workspace.isDefault
              return queue.fin()

            @createDefaultWorkspace machine, (err, workspace) ->

              return queue.fin()  if err

              workspaces.push workspace  if workspace
              queue.fin()

    sinkrow.dash queue, callback


  removeCollaborationMachine: (machine) ->

    @removeMachine 'collaboration', machine


  removeMachine: (type, machine) ->

    envData = globals.userEnvironmentData[type]

    for item, index in envData when item.machine.uid is machine.uid
      envData.splice index, 1
      kd.utils.defer => @fetch kd.noop
      return


  clearWorkspaces: (machine) ->

    for item in @getAllMachines() when item.machine.uid is machine.uid
      item.workspaces.splice 0
      return
