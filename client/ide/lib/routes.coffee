kd              = require 'kd'
nick            = require 'app/util/nick'
remote          = require 'app/remote'
actions         = require 'app/flux/environment/actions'
Machine         = require 'app/providers/machine'
lazyrouter      = require 'app/lazyrouter'
dataProvider    = require 'app/userenvironmentdataprovider'
isTeamReactSide = require 'app/util/isTeamReactSide'


selectWorkspaceOnSidebar = (data) ->

  return no  unless data

  { machine, workspace } = data

  return no if not machine or not workspace

  if isTeamReactSide()
    actions.setSelectedWorkspaceId workspace._id
  else
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

  return no  unless workspace

  { machineLabel, workspaceSlug, channelId } = workspace

  if dataProvider.findWorkspace machineLabel, workspaceSlug, channelId
    return workspace


loadIDENotFound = ->

  { appManager } = kd.singletons
  appManager.open 'IDE', { forceNew: yes }, (app) ->
    app.amIHost = yes
    appManager.tell 'IDE', 'showNoMachineState'


loadIDE = (data, done = kd.noop) ->

  { selectWorkspaceOnSidebar, findInstance } = module.exports

  { machine, workspace, username, channelId } = data
  selectWorkspaceOnSidebar data
  actions.setSelectedMachineId machine._id

  if machine.data?.generatedFrom?
    actions.setSelectedTemplateId machine.data.generatedFrom.templateId
  else
    actions.setSelectedTemplateId null

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
        # Don't remove this flag. Snapshot restoring procedure depends on this property.
        # If you want it, ping Turunc or Acet.
        app.amIHost           = yes

      app.mountMachineByMachineUId machineUId, done

  return callback()  unless ideApps?.instances

  ideInstance = findInstance machine, workspace

  if ideInstance
    appManager.showInstance ideInstance
    selectWorkspaceOnSidebar data # should not be required
  else
    callback()


findInstance = (machine, workspace) ->

  ideApps       = kd.singletons.appManager.appControllers.IDE
  machineUId    = machine.uid
  workspaceId   = workspace.getId()
  workspaceSlug = workspace.slug

  for instance in ideApps.instances
    isSameMachine   = instance.mountedMachineUId is machineUId
    isSameWorkspace = instance.workspaceData?.getId() is workspaceId

    if isSameMachine
      if isSameWorkspace then ideInstance = instance
      # should not be the case anymore since 'my-workspace' deprecated.
      else if workspaceSlug is 'my-workspace'
        if instance.workspaceData?.isDefault
          ideInstance = instance

  return ideInstance


routeToTestWorkspace = ->

  kd.singletons.router.handleRoute '/IDE/test-machine/test-workspace'


loadTestIDE = ->

  { workspaces } = machine = require('mocks/mockmanagedmachine')()
  machine = remote.revive machine
  workspace = remote.revive workspaces[0]
  { testController } = kd.singletons

  require('app/util/createTestMachine')().then ->
    loadIDE { machine, workspace, username: nick }, ->
      testController.prepare(machine, workspace)


routeToFallback = ->

  { routeToMachineWorkspace, loadIDENotFound } = module.exports

  machines = dataProvider.getMyMachines()
  [ obj ]  = machines

  if obj?.machine # `?` intentionally. there might be no machine.
    routeToMachineWorkspace obj.machine
  else
    loadIDENotFound()


routeToMachineWorkspace = (machine) ->

  { getLatestWorkspace } = module.exports

  latestWorkspace = getLatestWorkspace machine

  unless machine instanceof Machine
    machine = new Machine { machine }

  if latestWorkspace
  then { workspaceSlug } = latestWorkspace
  else workspaceSlug     = 'my-workspace'

  identifier = machine.slug

  if machine.isPermanent() or machine.jMachine.meta?.oldOwner
    identifier = machine.uid

  kd.getSingleton('router').handleRoute "/IDE/#{identifier}/#{workspaceSlug}"


routeToLatestWorkspace = ->

  { getLatestWorkspace, routeToFallback, routeToMachineWorkspace } = module.exports

  router          = kd.getSingleton 'router'
  latestWorkspace = getLatestWorkspace()

  return routeToFallback()  unless latestWorkspace

  { machineLabel, workspaceSlug, channelId } = latestWorkspace

  if channelId
    kd.singletons.socialapi.cacheable 'channel', channelId, (err, channel) ->

      if err
        storage = kd.singletons.localStorageController.storage 'IDE'
        storage.unsetKey 'LatestWorkspace'
        return routeToFallback()

      dataProvider.fetchMachineAndWorkspaceByChannelId channelId, (machine, ws) ->
        if machine and ws then router.handleRoute "/IDE/#{channelId}"
        else routeToFallback()

  else if machineLabel and workspaceSlug
    dataProvider.fetchMachineByLabel machineLabel, (machine, workspace) ->
      if machine and workspace
        actions.setSelectedWorkspaceId workspace._id
        router.handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"
      else if machine
        routeToMachineWorkspace machine
      else
        routeToFallback()

  # I think we should add an else case here to call routeToFallback because if
  # we don't have channelId, machineLabel and workspaceSlug at the same time
  # we will probably end up with a WSOD. // acet


loadCollaborativeIDE = (id) ->

  { routeToLatestWorkspace, loadIDE } = module.exports

  kd.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

    return routeToLatestWorkspace()  if err

    try

      dataProvider.fetchMachineAndWorkspaceByChannelId id, (machine, workspace) ->
        return routeToLatestWorkspace()  unless workspace

        query = { socialApiId: channel.creatorId }

        remote.api.JAccount.some query, {}, (err, account) ->
          if err
            routeToLatestWorkspace()
            return throw new Error err

          username  = account.first.profile.nickname
          channelId = channel.id

          return loadIDE { machine, workspace, username, channelId }

    catch e

      routeToLatestWorkspace()
      return console.error e


routeHandler = (type, info, state, path, ctx) ->

  # This is just a dirty workaround to be able to run the unit tests because
  # exported functions are not the same functions as the defined ones,
  # this is to make spies work in the future we hope to find a better way and
  # remove this imports. -- acet /cc usirin
  { routeToLatestWorkspace, loadCollaborativeIDE, routeToMachineWorkspace, loadIDE } = module.exports

  switch type

    when 'home' then routeToLatestWorkspace()

    when 'machine'
      { machineLabel } = info.params

      # we assume that if machineLabel is all numbers it is the channelId - SY
      if /^[0-9]+$/.test machineLabel
        loadCollaborativeIDE machineLabel
      else if machineLabel is 'test-machine'
        routeToTestWorkspace()
      else
        dataProvider.fetchMachine machineLabel, (machine) ->
          if machine then routeToMachineWorkspace machine
          else routeToLatestWorkspace()

    when 'workspace'
      { params } = info

      if params.workspaceSlug is 'test-workspace'
        return loadTestIDE()

      dataProvider.fetchMachine params.machineLabel, (machine) ->

        dataProvider.ensureDefaultWorkspace ->

          if machine
            username = machine.getOwner()
            data = { machineUId: machine.uid, workspaceSlug: params.workspaceSlug }

            dataProvider.fetchWorkspaceByMachineUId data, (workspace) ->
              if workspace then loadIDE { machine, workspace, username }
              else
                routeToMachineWorkspace machine

          else
            routeToLatestWorkspace()


module.exports = {

  selectWorkspaceOnSidebar
  getLatestWorkspace
  loadIDENotFound
  loadIDE
  routeToFallback
  routeToMachineWorkspace
  routeToLatestWorkspace
  loadCollaborativeIDE
  findInstance
  routeHandler

  init: -> lazyrouter.bind 'ide', (type, info, state, path, ctx) ->

    routeHandler type, info, state, path, ctx

}
