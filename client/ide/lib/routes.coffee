kd = require 'kd'
nick = require 'app/util/nick'
whoami = require 'app/util/whoami'
registerRoutes = require 'app/util/registerRoutes'
globals = require 'globals'
remote = require('app/remote').getInstance()
Machine = require 'app/providers/machine'
lazyrouter = require 'app/lazyrouter'
dataProvider = require 'app/userenvironmentdataprovider'


selectWorkspaceOnSidebar = (data) ->

  { machine, workspace } = data

  return  unless machine or workspace

  kd.getSingleton('mainView').activitySidebar.selectWorkspace data
  storage = kd.singletons.localStorageController.storage 'IDE'

  workspaceData    =
    machineLabel   : machine.slug or machine.label
    workspaceSlug  : workspace.slug
    channelId      : workspace.channelId

  storage.setValue 'LatestWorkspace', workspaceData
  storage.setValue "LatestWorkspace_#{machine.uid}", workspaceData


getLatestWorkspace = (machine) ->

  storage   = kd.getSingleton('localStorageController').storage 'IDE'
  if machine
    workspace = storage.getValue "LatestWorkspace_#{machine.uid}"

  unless machine and workspace
    workspace = storage.getValue 'LatestWorkspace'

  return  unless workspace

  { machineLabel, workspaceSlug, channelId } = workspace

  if dataProvider.findWorkspace machineLabel, workspaceSlug, channelId
    return workspace


loadIDENotFound = ->

  {appManager} = kd.singletons
  appManager.open 'IDE', { forceNew: yes }, (app) ->
    app.amIHost = yes
    appManager.tell 'IDE', 'createMachineStateModal', state: 'NotFound'


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

      app.mountMachineByMachineUId machineUId

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

  if obj?.machine # `?` intentionally. there might be no machine.
    routeToMachineWorkspace obj.machine
  else
    loadIDENotFound()


routeToMachineWorkspace = (machine) ->

  latestWorkspace = getLatestWorkspace machine
  workspaceSlug   = 'my-workspace'

  if latestWorkspace
    { machineLabel } = latestWorkspace
    if machineLabel is machine.label
      workspaceSlug = latestWorkspace.workspaceSlug

  kd.getSingleton('router').handleRoute "/IDE/#{machine.slug}/#{workspaceSlug}"


routeToLatestWorkspace = ->

  router          = kd.getSingleton 'router'
  latestWorkspace = getLatestWorkspace()

  return routeToFallback()  unless latestWorkspace

  { machineLabel, workspaceSlug, channelId } = latestWorkspace

  if channelId
    dataProvider.fetchMachineAndWorkspaceByChannelId channelId, (machine, ws) =>
      if machine and ws then router.handleRoute "/IDE/#{channelId}"
      else routeToFallback()

  else if machineLabel and workspaceSlug
    dataProvider.fetchMachineByLabel machineLabel, (machine, workspace) =>
      if machine and workspace
        router.handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"
      else if machine
        routeToMachineWorkspace machine
      else
        routeToFallback()


loadCollaborativeIDE = (id) ->

  kd.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

    return routeToLatestWorkspace()  if err

    try

      dataProvider.fetchMachineAndWorkspaceByChannelId id, (machine, workspace) =>
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


module.exports = -> lazyrouter.bind 'ide', (type, info, state, path, ctx) ->

  switch type

    when 'home' then routeToLatestWorkspace()

    when 'machine'
      { machineLabel } = info.params

      # we assume that if machineLabel is all numbers it is the channelId - SY
      if /^[0-9]+$/.test machineLabel then loadCollaborativeIDE machineLabel
      else
        dataProvider.fetchMachine machineLabel, (machine) ->
          if machine then routeToMachineWorkspace machine
          else routeToLatestWorkspace()

    when 'workspace'
      { params } = info

      dataProvider.fetchMachine params.machineLabel, (machine) =>

        if machine
          username = machine.getOwner()
          data = machineUId: machine.uid, workspaceSlug: params.workspaceSlug

          dataProvider.fetchWorkspaceByMachineUId data, (workspace) =>
            if workspace then loadIDE { machine, workspace, username }
            else routeToMachineWorkspace machine

        else
          routeToLatestWorkspace()
