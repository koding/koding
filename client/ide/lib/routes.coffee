kd = require 'kd'
nick = require 'app/util/nick'
whoami = require 'app/util/whoami'
registerRoutes = require 'app/util/registerRoutes'
globals = require 'globals'
remote = require('app/remote').getInstance()
Machine = require 'app/providers/machine'
lazyrouter = require 'app/lazyrouter'
dataProvider = require 'app/userenvironmentdataprovider'


# loadWorkspace = (workspace, options) ->

#   {machine, machineLabel, username} = options

#   username or= nick()
#   machine  or= getMachine machineLabel, username

#   loadIDE { machine, workspace, username }


# findWorkspace = (options, callback) ->

#   {machineLabel, workspaceSlug, username} = options

#   kallback = (workspaces) ->

#     username ?= nick()

#     for machine in globals.userMachines
#       unless machine instanceof Machine
#         machine = new Machine machine: remote.revive machine

#       sameLabel = (machine.slug or machine.label) is machineLabel
#       sameOwner = machine.getOwner() is username

#       if sameLabel and sameOwner
#         machineUId = machine.uid
#         break

#     for workspace in workspaces
#       continue  unless workspace.machineUId is machineUId
#       continue  unless workspace.slug is workspaceSlug

#       return callback workspace

#     return callback null

#   if username
#   then filterWorkspacesByUsername username, kallback
#   else filterOwnWorkspaces kallback


# filterWorkspacesByUsername = (username, callback) ->

#   remote.cacheable username, (err, [account]) ->
#     if err
#       console.error err
#       callback []

#     originId = account.getId()

#     callback globals.userWorkspaces.filter (workspace) ->
#       originId is workspace.originId


# filterOwnWorkspaces = (callback) ->

#   callback globals.userWorkspaces.filter (workspace) ->
#     workspace.originId is whoami()._id


selectWorkspaceOnSidebar = (data) ->

  mainView = kd.getSingleton 'mainView'
  mainView.activitySidebar.selectWorkspace data


# getMachine = (label, username = nick()) ->

#   for m in globals.userMachines

#     unless m instanceof Machine
#       m = new Machine machine: remote.revive m

#     sameUser  = m.getOwner() is username
#     sameLabel = (m.slug or m.label) is label

#     return m  if sameLabel and sameUser


getLatestWorkspace = ->

  storage   = kd.getSingleton('localStorageController').storage 'IDE'
  workspace = storage.getValue 'LatestWorkspace'

  return  unless workspace

  { machineLabel, workspaceSlug, channelId } = workspace

  ws = null

  if checkWorkspace machineLabel, workspaceSlug, channelId
   ws = workspace

  return ws


checkWorkspace = (machineLabel, workspaceSlug, channelId) ->

  return dataProvider.validateCollaborationWorkspace machineLabel, workspaceSlug, channelId

  # for workspace in globals.userWorkspaces
  #   sameLabel = workspace.machineLabel is machineLabel
  #   sameSlug = workspace.slug is workspaceSlug
  #   sameChannelId = not channelId or workspace.channelId is channelId

  #   if sameLabel and sameSlug and sameChannelId
  #     return workspace


loadIDE = (data) ->

  { machine, workspace, username, channelId } = data
  selectWorkspaceOnSidebar data

  appManager = kd.getSingleton 'appManager'
  ideApps    = appManager.appControllers.IDE
  machineUId = machine.uid
  callback   = ->
    appManager.open 'IDE', { forceNew: yes }, (app) ->
      app.mountedMachineUId   = machineUId
      app.workspaceData       = workspace

      if username and username isnt nick()
        app.isInSession       = yes
        app.amIHost           = no
        app.collaborationHost = username
        app.channelId         = channelId
      else
        app.amIHost           = yes

      appManager.tell 'IDE', 'mountMachineByMachineUId', machineUId

  return callback()  unless ideApps?.instances

  for instance in ideApps.instances
    isSameMachine   = instance.mountedMachineUId is machineUId
    isSameWorkspace = instance.workspaceData?.getId() is workspace.getId()

    if isSameMachine
      if isSameWorkspace then ideInstance = instance
      # should not be the case anymore since 'my-workspace' deprecated.
      else if workspace.slug is 'my-workspace'
        if instance.workspaceData?.isDefault
          ideInstance = instance

  if ideInstance
    appManager.showInstance ideInstance
    selectWorkspaceOnSidebar data # should not be required
  else
    callback()


routeToFallback = ->

  machines = dataProvider.getMyMachines()
  router   = kd.getSingleton 'router'
  [ obj ]  = machines

  if obj.machine
    routeToMachineWorkspace obj.machine
  else
    router.handleRoute "/IDE/koding-vm-0/my-workspace"


  # router = kd.getSingleton 'router'

  # for machine in globals.userMachines when machine.isMine()
  #   return routeToMachineWorkspace machine

  # kd.singletons.computeController.fetchMachines (err, machines) ->

  #   if err or not machines.length
  #   then router.handleRoute "/IDE/koding-vm-0/my-workspace"
  #   else routeToMachineWorkspace machines.first


routeToMachineWorkspace = (machine) ->

  latestWorkspace = getLatestWorkspace()
  workspaceSlug   = 'my-workspace'

  if latestWorkspace
    { machineLabel } = latestWorkspace
    if machineLabel is machine.label
      workspaceSlug = latestWorkspace.workspaceSlug

  kd.getSingleton('router').handleRoute "/IDE/#{machine.slug}/#{workspaceSlug}"

  # if latestWorkspace = getLatestWorkspace()
  #   {machineLabel} = latestWorkspace
  #   if machineLabel is machine.label
  #     workspaceSlug = latestWorkspace.workspaceSlug

  # workspaceSlug ?= 'my-workspace'

  # kd.getSingleton('router').handleRoute "/IDE/#{machine.slug}/#{workspaceSlug}"


routeToLatestWorkspace = ->

  router          = kd.getSingleton 'router'
  latestWorkspace = getLatestWorkspace()

  return routeToFallback()  unless latestWorkspace

  { machineLabel, workspaceSlug, channelId } = latestWorkspace

  if channelId
    dataProvider.getMachineAndWorkspaceByChannelId channelId, (machine, ws) =>
      if machine and ws then router.handleRoute "/IDE/#{channelId}"
      else routeToFallback()

  else if machineLabel and workspaceSlug
    dataProvider.getMachineByLabel machineLabel, (machine, workspace) =>
      if machine and workspace
        router.handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"
      else if machine
        routeToMachineWorkspace machine
      else
        routeToFallback()


  # router = kd.getSingleton 'router'

  # if latestWorkspace = getLatestWorkspace()
  #   {machineLabel, workspaceSlug, channelId} = latestWorkspace
  # else
  #   return routeToFallback()

  # if channelId
  #   for workspace in globals.userWorkspaces when workspace.channelId is channelId
  #     return router.handleRoute "/IDE/#{channelId}"
  #   routeToFallback()

  # else if machineLabel and workspaceSlug
  #   return routeToFallback()  unless machine = getMachine machineLabel

  #   findWorkspace {workspaceSlug, machineLabel}, (workspace) ->

  #     if workspace
  #     then router.handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"
  #     else routeToMachineWorkspace machine


loadCollaborativeIDE = (id) ->

  kd.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

    return routeToLatestWorkspace()  if err

    try

      dataProvider.getMachineAndWorkspaceByChannelId id, (machine, workspace) =>
        return routeToLatestWorkspace()  unless workspace

        query = socialApiId: channel.creatorId

        remote.api.JAccount.some query, {}, (err, account) =>
          if err
            routeToLatestWorkspace()
            return throw new Error err

          username  = account.first.profile.nickname
          channelId = channel.id

          return loadIDE { machine, workspace, username, channelId }

    catch e

      routeToLatestWorkspace()
      return console.error e


  # kd.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

  #   return routeToLatestWorkspace()  if err

  #   try

  #     [workspace] = globals.userWorkspaces.filter (w) -> w.channelId is channel.id

  #     return routeToLatestWorkspace()  unless workspace

  #     [machine] = globals.userMachines.filter (m) -> m.uid is workspace.machineUId

  #     query = socialApiId: channel.creatorId
  #     remote.api.JAccount.some query, {}, (err, account) =>

  #       return throw new Error err  if err

  #       username  = account.first.profile.nickname
  #       channelId = channel.id

  #       return loadIDE { machine, workspace, username, channelId }

  #   catch e

  #     console.error e
  #     return routeToLatestWorkspace()


# refreshWorkspaces = (callback) ->

#   {mainView, computeController} = kd.singletons

#   computeController.ready ->
#     mainView.activitySidebar.fetchWorkspaces callback


module.exports = -> lazyrouter.bind 'ide', (type, info, state, path, ctx) ->

  globals.userMachines = []
  globals.userWorkspaces = []

  switch type

    when 'home' then routeToLatestWorkspace()

    when 'machine'
      { machineLabel } = info.params

      # we assume that if machineLabel is all numbers it is the channelId - SY
      if /^[0-9]+$/.test machineLabel
        loadCollaborativeIDE machineLabel
      else
        dataProvider.getMachineByLabel machineLabel, (machine) ->
          if machine then routeToMachineWorkspace machine
          else routeToLatestWorkspace()

      # {machineLabel} = info.params
      # # we assume that if machineLabel is all numbers it is the channelId - SY
      # if /^[0-9]+$/.test machineLabel
      #   refreshWorkspaces -> loadCollaborativeIDE machineLabel
      # else if machine = getMachine machineLabel
      #   routeToMachineWorkspace machine
      # else
      #   routeToLatestWorkspace()


    when 'workspace'
      { params } = info
      params.username = username = nick()

      dataProvider.getMachineAndWorkspace params, (machine, workspace) ->

        if machine and workspace
          loadIDE { machine, workspace, username }
        else if machine
          routeToMachineWorkspace machine
        else
          routeToLatestWorkspace()

      # {params} = info
      # {machineLabel} = params
      # params.username = nick()

      # refreshWorkspaces ->

      #   findWorkspace params, (workspace) ->

      #     if workspace
      #       return loadWorkspace workspace, params
      #     else
      #       for machine in globals.userMachines when machine.slug is machineLabel
      #         break

      #       if machine
      #       then routeToMachineWorkspace machine
      #       else loadWorkspace null, params

      #     routeToLatestWorkspace()
