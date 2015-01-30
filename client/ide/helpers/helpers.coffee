IDE.helpers =

  # This helper method will emit `WorkspaceCreateFailed` or `WorkspaceCreated`
  # event by using the `options.eventObj`. So you must pass an `eventObj` in
  # options to communicate with the delegate. Because this helper method has no
  # ability to emit events.
  createWorkspace: (options) ->

    { name, machineUId, rootPath, machineLabel, eventObj } = options
    { computeController, router } = KD.singletons

    if not name or not machineUId or not eventObj
      warn 'Missing options to create a new workspace'
      return IDE.helpers.handleWorkspaceCreateError_ eventObj

    machine = m for m in computeController.machines when m.uid is machineUId
    layout  = {}
    data    = { name, machineUId, machineLabel, rootPath, layout }

    unless machine
      warn "Machine not found."
      return IDE.helpers.handleWorkspaceCreateError_ eventObj

    KD.remote.api.JWorkspace.create data, (err, workspace) =>
      return IDE.helpers.handleWorkspaceCreateError_ eventObj  if err

      folderOptions  =
        type         : 'folder'
        path         : workspace.rootPath
        recursive    : yes
        samePathOnly : yes

      machine.fs.create folderOptions, (err, folder) =>
        return IDE.helpers.handleWorkspaceCreateError_ eventObj  if err

        filePath   = "#{workspace.rootPath}/README.md"
        readMeFile = FSHelper.createFileInstance { path: filePath, machine }

        readMeFile.save IDE.contents.workspace, (err) =>
          return IDE.helpers.handleWorkspaceCreateError_ eventObj  if err

          eventObj.emit 'WorkspaceCreated', workspace

          href = "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
          router.handleRoute href


  handleWorkspaceCreateError_: (eventObj, error) ->

    eventObj.emit 'WorkspaceCreateFailed'
    KD.showError "Couldn't create your new workspace."
