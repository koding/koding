do ->

  loadWorkspace = (machineLabel, workspaceSlug) ->
    workspace = ws  for ws in KD.userWorkspaces when ws.slug is workspaceSlug
    machine   = getMachineByLabel machineLabel

    if workspace
      loadIDE { machine, workspace }
    else
      if workspaceSlug is 'my-workspace'
        workspace = isDefault: yes, slug: 'my-workspace', machineLabel: machine?.label
        loadIDE { machine, workspace }
      else
        routeToLatestWorkspace()


  selectWorkspaceOnSidebar = (data) ->
    mainView = KD.getSingleton 'mainView'
    mainView.activitySidebar.selectWorkspace data


  getMachineByLabel = (label) ->
    machine = m  for m in KD.userMachines when m.label is label
    return machine or null


  loadIDE = (data) ->
    { machine, workspace } = data

    appManager = KD.getSingleton 'appManager'
    ideApps    = appManager.appControllers.IDE
    machineUId = machine?.uid
    fallback   = ->
      appManager.open 'IDE', { forceNew: yes }, (app) ->
        app.mountedMachineUId = machineUId
        app.workspaceData     = workspace

        appManager.tell 'IDE', 'mountMachineByMachineUId', machineUId
        selectWorkspaceOnSidebar data

    return fallback()  unless ideApps?.instances

    for instance in ideApps.instances
      isSameMachine   = instance.mountedMachineUId is machineUId
      isSameWorkspace = instance.workspaceData is workspace

      if isSameMachine
        if isSameWorkspace then ideInstance = instance
        else if workspace.slug is 'my-workspace'
          if instance.workspaceData?.isDefault
            ideInstance = instance

    if ideInstance
      appManager.showInstance ideInstance
      selectWorkspaceOnSidebar data
    else
      fallback()


  routeToLatestWorkspace = ->
    localStorage    = KD.getSingleton("localStorageController").storage "IDE"
    latestWorkspace = localStorage.getValue 'LatestWorkspace'

    if latestWorkspace
      {machineLabel, workspaceSlug} = latestWorkspace
    else
      machineLabel  = KD.userMachines.first?.label or ''
      workspaceSlug = 'my-workspace'

    KD.getSingleton('router').handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"


  KD.registerRoutes 'IDE',

    '/:name?/IDE': -> routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel/:workspaceSlug': (data) ->

      { machineLabel, workspaceSlug } = data.params

      loadWorkspace machineLabel, workspaceSlug
