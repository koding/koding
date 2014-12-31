do ->

  loadWorkspace = (options, workspace) ->

    {machineLabel, workspaceSlug, username} = options

    machine = getMachine machineLabel, username

    if workspace
      loadIDE { machine, workspace, username }

    else if workspaceSlug is 'my-workspace'
      workspace = new KD.remote.api.JWorkspace
        _id          : 'my-workspace'
        isDummy      : yes
        isDefault    : yes
        slug         : 'my-workspace'
        machineLabel : machine?.slug or machine?.label

      loadIDE { machine, workspace, username }

    else
      routeToLatestWorkspace()


  findWorkspace = (options, callback) ->

    {machineLabel, workspaceSlug, username} = options

    kallback = (workspaces) ->

      for workspace in workspaces
        continue  unless workspace.machineLabel is machineLabel
        continue  unless workspace.slug is workspaceSlug

        return callback workspace

      return callback null

    if username
    then filterWorkspacesByUsername username, kallback
    else kallback KD.userWorkspaces


  filterWorkspacesByUsername = (username, callback) ->

    KD.remote.cacheable username, (err, [account]) ->
      if err
        console.error err
        callback []

      originId = account.getId()

      callback KD.userWorkspaces.filter (workspace) ->
        originId is workspace.originId


  selectWorkspaceOnSidebar = (data) ->
    mainView = KD.getSingleton 'mainView'
    mainView.activitySidebar.selectWorkspace data


  getMachine = (label, username) ->
    machine = null

    for m in KD.userMachines
      hasSameLabel = (m.label is label) or (m.slug is label)
      hasSameUser  = m.data.credential is username

      if hasSameLabel and hasSameUser
        machine = m

    return machine


  loadIDE = (data) ->

    { machine, workspace, username, channelId } = data

    appManager = KD.getSingleton 'appManager'
    ideApps    = appManager.appControllers.IDE
    machineUId = machine?.uid
    callback   = ->
      appManager.open 'IDE', { forceNew: yes }, (app) ->
        app.mountedMachineUId   = machineUId
        app.workspaceData       = workspace

        if username and username isnt KD.nick()
          app.isInSession       = yes
          app.amIHost           = no
          app.collaborationHost = username
          app.channelId         = channelId
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

    KD.utils.defer ->
      KD.getSingleton('router').handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"


  routeToLatestWorkspace = (options = {}) ->

    {params}       = options
    {machineLabel} = params  if params

    # we assume that if machineLabel is all numbers it is the channelId - SY
    return loadCollaborativeIDE machineLabel  if machineLabel and /^[0-9]+$/.test machineLabel

    machine = KD.userMachines.first
    return putVMInWorkspace machine  if machine

    KD.singletons.computeController.fetchMachines (err, machines)->

      if err or not machines.length
        KD.getSingleton('router').handleRoute "/IDE/koding-vm-0/my-workspace"
        return

      putVMInWorkspace machines.first


  loadCollaborativeIDE = (id) ->

    KD.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

      return routeToLatestWorkspace()  if err

      try

        return routeToLatestWorkspace()  unless KD.userWorkspaces.length

        KD.userWorkspaces.forEach (workspace, index) =>

          if workspace.channelId is channel.id

            machine = (KD.userMachines.filter (m) -> m.uid is workspace.machineUId)[0]
            query   = socialApiId: channel.creatorId

            KD.remote.api.JAccount.some query, {}, (err, account) =>

              return throw new Error err  if err

              username  = account.first.profile.nickname
              channelId = channel.id

              return loadIDE { machine, workspace, username, channelId }

          # Commented out because of the side effects. ~Umut
          # (e.g can't select random vms/workspaces)

          # else
          #   if index + 1 is KD.userWorkspaces.length
          #     routeToLatestWorkspace()

      catch e

        console.error e
        return routeToLatestWorkspace()


  refreshWorkspaces = (callback) ->

    KD.singletons.mainView.activitySidebar.fetchWorkspaces callback


  KD.registerRoutes 'IDE',

    '/:name?/IDE': (rest...) ->
      refreshWorkspaces -> routeToLatestWorkspace rest...

    '/:name?/IDE/:machineLabel': (rest...) ->
      refreshWorkspaces -> routeToLatestWorkspace rest...

    '/:name?/IDE/:machineLabel/:workspaceSlug': (routeInfo) ->

      {params} = routeInfo
      params.username or= KD.nick()

      refreshWorkspaces ->

        findWorkspace params, (workspace) ->

          loadWorkspace params, workspace
