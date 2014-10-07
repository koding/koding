do ->

  loadWorkspace = (machineLabel, workspaceSlug) ->
    workspace = ws  for ws in KD.userWorkspaces when ws.slug is workspaceSlug
    machine   = getMachineByLabel machineLabel

    if workspace
      loadIDE { machine, workspace }
    else
      if workspaceSlug is 'my-workspace'
        workspace = isDefault: yes, slug: 'my-workspace', machineLabel: machine?.slug or machine?.label
        loadIDE { machine, workspace }
      else
        routeToLatestWorkspace()


  selectWorkspaceOnSidebar = (data) ->
    mainView = KD.getSingleton 'mainView'
    mainView.activitySidebar.selectWorkspace data


  getMachineByLabel = (label) ->
    machine = m  for m in KD.userMachines when (m.label is label) or (m.slug is label)
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


  putVMInWorkspace = (machine)->
    localStorage    = KD.getSingleton("localStorageController").storage "IDE"
    latestWorkspace = localStorage.getValue 'LatestWorkspace'

    machineLabel    = machine?.slug or machine?.label or ''
    workspaceSlug   = 'my-workspace'

    if latestWorkspace
      for ws in KD.userWorkspaces when ws.slug is latestWorkspace.workspaceSlug
        {machineLabel, workspaceSlug} = latestWorkspace

    KD.getSingleton('router').handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"


  routeToLatestWorkspace = ->
    machine = KD.userMachines.first

    if machine?
      return putVMInWorkspace machine

    KD.singletons.computeController.fetchMachines (err,  machines)->
      if err or not machines.length
        KD.getSingleton('router').handleRoute "/Activity"

      putVMInWorkspace machines.first


  KD.registerRoutes 'IDE',

    '/:name?/IDE': -> routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel': -> routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel/:workspaceSlug': (data) ->

      { machineLabel, workspaceSlug } = data.params

      loadWorkspace machineLabel, workspaceSlug
