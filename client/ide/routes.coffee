do ->

  loadWorkspace = (machineLabel, workspaceSlug, username) ->
    workspace = ws  for ws in KD.userWorkspaces when ws.slug is workspaceSlug
    machine   = getMachineByLabel machineLabel

    if workspace
      loadIDE { machine, workspace, username }
    else
      if workspaceSlug is 'my-workspace'
        workspace = isDefault: yes, slug: 'my-workspace', machineLabel: machine?.slug or machine?.label
        loadIDE { machine, workspace, username }
      else
        routeToLatestWorkspace()


  selectWorkspaceOnSidebar = (data) ->
    mainView = KD.getSingleton 'mainView'
    mainView.activitySidebar.selectWorkspace data


  getMachineByLabel = (label) ->
    machine = m  for m in KD.userMachines when (m.label is label) or (m.slug is label)
    return machine or null


  loadIDE = (data) ->
    { machine, workspace, username } = data

    appManager = KD.getSingleton 'appManager'
    ideApps    = appManager.appControllers.IDE
    machineUId = machine?.uid
    callback   = ->
      appManager.open 'IDE', { forceNew: yes }, (app) ->
        app.mountedMachineUId   = machineUId
        app.workspaceData       = workspace

        if username
          app.isCollaborative   = yes
          app.collaborationHost = username
          app.amIHost           = no
        else
          app.amIHost           = yes

        appManager.tell 'IDE', 'mountMachineByMachineUId', machineUId
        selectWorkspaceOnSidebar data

    return callback()  unless ideApps?.instances

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
      callback()


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

    return putVMInWorkspace machine  if machine

    KD.singletons.computeController.fetchMachines (err,  machines)->
      if err or not machines.length
        KD.getSingleton('router').handleRoute "/IDE/koding-vm-0/my-workspace"

      putVMInWorkspace machines.first


  KD.registerRoutes 'IDE',

    '/:name?/IDE': -> routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel': -> routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel/:workspaceSlug': (data) ->

      { machineLabel, workspaceSlug } = data.params

      loadWorkspace machineLabel, workspaceSlug

    '/:name?/IDE/:machineLabel/:workspaceSlug/:username': (data) ->

      { machineLabel, workspaceSlug, username } = data.params

      loadWorkspace machineLabel, workspaceSlug, username
