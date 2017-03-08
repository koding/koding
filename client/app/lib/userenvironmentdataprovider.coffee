_       = require 'lodash'
kd      = require 'kd'
globals = require 'globals'
remote  = require 'app/remote'
Machine = require 'app/providers/machine'
async   = require 'async'

runMiddlewares = require 'app/util/runMiddlewares'
TestMachineMiddleware = require 'app/providers/middlewares/testmachine'

KDNotificationView = kd.NotificationView


module.exports =

  getMiddlewares: ->
    return [
      TestMachineMiddleware.EnvironmentDataProvider
    ]


  fetch: (callback) ->

    callback do @setDefaults_


  addTestMachine: (machine) ->
    @_testMachine = { machine }
    @revive()


  get: ->
    console.trace()
    return @setDefaults_ globals.userEnvironmentData


  setDefaults_: (data = {}) ->

    data.own           or= []
    data.shared        or= []
    data.collaboration or= []

    return runMiddlewares.sync this, 'setDefaults_', data


  hasData: ->

    data = @get()

    return  no unless data

    hasOwn    = data.own.length > 0
    hasShared = data.shared.length > 0
    hasCollab = data.collaboration.length > 0

    return hasOwn or hasShared or hasCollab


  revive: ->

    return no  unless @hasData()

    for __, section of @get()
      for obj in section
        obj.machine = remote.revive obj.machine
        for ws, i in obj.workspaces
          obj.workspaces[i] = remote.revive ws


  getMyMachines: -> @get().own


  getSharedMachines: ->

    { shared } = @get()

    return shared.concat @getCollaborationMachines()


  getCollaborationMachines: ->

    return @get().collaboration


  getAllMachines: ->

    { own, shared, collaboration } = @get()

    return own.concat shared.concat collaboration


  getRunningMachines: ->

    @getAllMachines().filter (vm) -> vm.machine.status.state is 'Running'


  getMachineWithPredicate: (fn, predicate) ->

    @getAllMachines().filter(predicate)[0]


  fetchMachine: (identifier, callback) ->

    @fetchMachineBySlug identifier, (machine) =>
      return callback new Machine { machine }  if machine

      @fetchMachineByLabel identifier, (machine) =>
        return  callback new Machine { machine }  if machine

        @fetchMachineByUId identifier, (machine) ->
          machine = if machine then new Machine { machine } else null

          callback machine


  # FIXMEWS ~ GG
  fetchWorkspacesByMachineUId: (machineUId, callback) ->

    for obj in @getAllMachines()
      if obj.machine.uid is machineUId
        callback obj.workspaces
        break


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


  # FIXMEWS ~ GG
  findWorkspace: (machineLabel, workspaceSlug, channelId) ->

    for item in @getAllMachines()

      { machine, workspaces } = item

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

    for i in IDE.instances when i.mountedMachineUId is uid
      instance = i
      break

    return instance


  removeCollaborationMachine: (machine) ->

    @removeMachine 'collaboration', machine


  removeMachine: (type, machine) ->

    envData = globals.userEnvironmentData[type]

    for item, index in envData when item.machine.uid is machine.uid
      envData.splice index, 1
      kd.utils.defer => @fetch kd.noop
      return
