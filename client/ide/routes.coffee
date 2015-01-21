do ->

  loadWorkspace = (workspace, options) ->

    {machine, machineLabel, username} = options

    username or= KD.nick()
    machine  or= getMachine machineLabel, username

    loadIDE { machine, workspace, username }


  findWorkspace = (options, callback) ->

    {machineLabel, workspaceSlug, username} = options

    kallback = (workspaces) ->

      username ?= KD.nick()

      for machine in KD.userMachines
        unless machine instanceof Machine
          machine = new Machine machine: KD.remote.revive machine

        sameLabel = (machine.slug or machine.label) is machineLabel
        sameOwner = machine.getOwner() is username

        if sameLabel and sameOwner
          machineUId = machine.uid
          break

      for workspace in workspaces
        continue  unless workspace.machineUId is machineUId
        continue  unless workspace.slug is workspaceSlug

        return callback workspace

      return callback null

    if username
    then filterWorkspacesByUsername username, kallback
    else filterOwnWorkspaces kallback


  filterWorkspacesByUsername = (username, callback) ->

    KD.remote.cacheable username, (err, [account]) ->
      if err
        console.error err
        callback []

      originId = account.getId()

      callback KD.userWorkspaces.filter (workspace) ->
        originId is workspace.originId


  filterOwnWorkspaces = (callback) ->

    callback KD.userWorkspaces.filter (workspace) ->
      workspace.originId is KD.whoami()._id


  selectWorkspaceOnSidebar = (data) ->
    mainView = KD.getSingleton 'mainView'
    mainView.activitySidebar.selectWorkspace data


  getMachine = (label, username = KD.nick()) ->

    for m in KD.userMachines

      unless m instanceof Machine
        m = new Machine machine: KD.remote.revive m

      sameUser  = m.getOwner() is username
      sameLabel = (m.label or m.slug) is label

      return m  if sameLabel and sameUser


  getLatestWorkspace = ->

    storage = KD.getSingleton('localStorageController').storage 'IDE'
    return storage.getValue 'LatestWorkspace'


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
      isSameWorkspace = instance.workspaceData?.getId() is workspace.getId()

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


  routeToFallback = ->

    router = KD.getSingleton 'router'

    for machine in KD.userMachines when machine.isMine()
      return routeToMachineWorkspace machine

    KD.singletons.computeController.fetchMachines (err, machines) ->

      if err or not machines.length
      then router.handleRoute "/IDE/koding-vm-0/my-workspace"
      else routeToMachineWorkspace machines.first


  routeToMachineWorkspace = (machine) ->

    if {machineLabel} = latestWorkspace = getLatestWorkspace()
      if machineLabel is machine.label
        workspaceSlug = latestWorkspace.workspaceSlug

    workspaceSlug ?= 'my-workspace'

    KD.getSingleton('router').handleRoute "/IDE/#{machine.label}/#{workspaceSlug}"


  routeToLatestWorkspace = ->

    router = KD.getSingleton 'router'

    if latestWorkspace = getLatestWorkspace()
      {machineLabel, workspaceSlug, channelId} = latestWorkspace
    else
      return routeToFallback()

    if channelId
      for workspace in KD.userWorkspaces when workspace.channelId is channelId
        return router.handleRoute "/IDE/#{channelId}"
      routeToFallback()

    else if machineLabel and workspaceSlug
      return routeToFallback()  unless machine = getMachine machineLabel

      findWorkspace {workspaceSlug, machineLabel}, (workspace) ->

        if workspace
        then router.handleRoute "/IDE/#{machineLabel}/#{workspaceSlug}"
        else routeToMachineWorkspace machine


  loadCollaborativeIDE = (id) ->

    KD.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

      return routeToLatestWorkspace()  if err

      try

        return routeToLatestWorkspace()  unless KD.userWorkspaces.length

        KD.userWorkspaces.forEach (workspace, index) =>

          return  if workspace.channelId isnt channel.id

          machine = (KD.userMachines.filter (m) -> m.uid is workspace.machineUId)[0]
          query   = socialApiId: channel.creatorId

          KD.remote.api.JAccount.some query, {}, (err, account) =>

            return throw new Error err  if err

            username  = account.first.profile.nickname
            channelId = channel.id

            return loadIDE { machine, workspace, username, channelId }

      catch e

        console.error e
        return routeToLatestWorkspace()


  refreshWorkspaces = (callback) ->

    {mainView, computeController} = KD.singletons

    computeController.ready ->
      mainView.activitySidebar.fetchWorkspaces callback


  KD.registerRoutes 'IDE',

    '/:name?/IDE': ->
      refreshWorkspaces -> routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel': ({params}) ->

      {machineLabel} = params

      # we assume that if machineLabel is all numbers it is the channelId - SY
      if /^[0-9]+$/.test machineLabel
        refreshWorkspaces -> loadCollaborativeIDE machineLabel
      else if machine = getMachine machineLabel
        routeToMachineWorkspace machine
      else
        routeToLatestWorkspace()

    '/:name?/IDE/:machineLabel/:workspaceSlug': ({params}) ->

      {machineLabel} = params

      params.username = KD.nick()

      refreshWorkspaces ->

        findWorkspace params, (workspace) ->

          if workspace
            return loadWorkspace workspace, params
          else
            for machine in KD.userMachines when machine.label is machineLabel
              break

            if machine
            then routeToMachineWorkspace machine
            else loadWorkspace null, params

          routeToLatestWorkspace()
