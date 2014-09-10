do ->

  loadWorkspace = (slug) ->
    workspace = ws  for ws in KD.userWorkspaces when ws.slug is slug

    if workspace
      machine = getMachineByUId workspace.machineUId
      loadIDE { machine, workspace } # TODO: Be sure we are handling machine not found
    else
      if slug is 'my-workspace'
        machine   = KD.userMachines.first
        workspace = isDefault: yes, slug: 'my-workspace'

        loadIDE { machine, workspace }
      else
        routeToLastWorkspace()


  getMachineByUId = (uid) ->
    machine = m  for m in KD.userMachines when m.uid is uid
    return machine or null


  loadIDE = ({ machine, workspace }) ->
    appManager = KD.getSingleton 'appManager'
    ideApps    = appManager.appControllers.IDE
    machineUId = machine.uid
    fallback   = ->
      appManager.open 'IDE', { forceNew: yes }, (app) ->
        app.mountedMachineUId = machineUId
        app.workspaceData     = workspace

        appManager.tell 'IDE', 'mountMachineByMachineUId', machineUId

    return fallback()  unless ideApps?.instances

    for instance in ideApps.instances
      isSameMachine   = instance.mountedMachineUId is machineUId
      isSameWorkspace = instance.workspaceData is workspace

      if isSameMachine and isSameWorkspace
        ideInstance   = instance
      else if workspace.slug is 'my-workspace'
        if instance.workspaceData?.isDefault
          ideInstance = instance

    if ideInstance then appManager.showInstance ideInstance else fallback()


  routeToLastWorkspace = ->
    KD.getSingleton('router').handleRoute '/IDE/my-workspace'


  KD.registerRoutes 'IDE',

    '/:name?/IDE': -> routeToLastWorkspace()

    '/:name?/IDE/:workspaceSlug': (data) ->
      loadWorkspace data.params.workspaceSlug
