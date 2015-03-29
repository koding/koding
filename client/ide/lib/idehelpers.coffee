remote = require('app/remote').getInstance()
showError = require 'app/util/showError'
kd = require 'kd'
globals = require 'globals'
FSHelper = require 'app/util/fs/fshelper'
FilePermissionsModal = require './views/modals/filepermissionsmodal'

WORKSPACE_WELCOME_TXT = """
  # Awesome, you've just made a new workspace!
  Workspaces are fantastic for organizing your work. This new workspace, which lives inside the 'Workspaces' folder of your home
  directory, is a place where you can store all relevant and related files to a particular project. For example, if you
  are working on multiple projects, its nice to have them separated as follows:
  -|home dir
     -|Workspaces
      -| Project 1
      -| Project 2
      -| Project 3

  Workspaces help keep your projects organized. You can create any number of workspaces. There are no limits.

  Note: A workspace folder is just a regular folder so you can create any number of files and folders inside it.

  As you move back and forth between your workspaces, Koding will remember everything about each workspace. This includes things
  like IDE settings, files open, Terminals open, etc.

  Enjoy and Happy Koding!
"""

module.exports = helpers =

  # This helper method will emit `WorkspaceCreateFailed` or `WorkspaceCreated`
  # event by using the `options.eventObj`. So you must pass an `eventObj` in
  # options to communicate with the delegate. Because this helper method has no
  # ability to emit events.
  createWorkspace: (options) ->

    { name, machineUId, rootPath, machineLabel, eventObj } = options
    { computeController, router } = kd.singletons

    if not name or not machineUId or not eventObj
      err = message: 'Missing options to create a new workspace'
      return helpers.handleWorkspaceCreateError_ eventObj, err

    machine = m for m in computeController.machines when m.uid is machineUId
    layout  = {}
    data    = { name, machineUId, machineLabel, rootPath, layout }

    unless machine
      err = mesage: "Machine not found."
      return helpers.handleWorkspaceCreateError_ eventObj, err

    #look for workspace by rootPath in globals.userEnvironmentData
    workspaces = o.workspaces for o in globals?.userEnvironmentData?.own when o.machine.uid is machineUId
    workspace = w for w in workspaces when w.rootPath is rootPath

    handleRout_ = (machine, workspace) ->
      href = "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
      router.handleRoute href

    return handleRout_(machine, workspace) if workspace

    remote.api.JWorkspace.create data, (err, workspace) =>
      return helpers.handleWorkspaceCreateError_ eventObj, err  if err

      folderOptions  =
        type         : 'folder'
        path         : workspace.rootPath
        recursive    : yes
        samePathOnly : yes

      machine.fs.create folderOptions, (err, folder) =>
        return helpers.handleWorkspaceCreateError_ eventObj, err  if err

        filePath   = "#{workspace.rootPath}/README.md"
        readMeFile = FSHelper.createFileInstance { path: filePath, machine }

        readMeFile.save WORKSPACE_WELCOME_TXT, (err) =>
          return helpers.handleWorkspaceCreateError_ eventObj, err  if err

          eventObj.emit 'WorkspaceCreated', workspace

          handleRout_(machine, workspace)


  handleWorkspaceCreateError_: (eventObj, error) ->

    eventObj.emit 'WorkspaceCreateFailed', error
    showError "Couldn't create your new workspace."
    kd.warn error


  showFileReadOnlyNotification: ->

    new FilePermissionsModal
      title      : 'Read-only file'
      contentText: 'You can proceed with opening the file but it will open in read-only mode.'


  showFileAccessDeniedError: ->

    new FilePermissionsModal
      title      : 'Access Denied'
      contentText: 'The file can\'t be opened because you don\'t have permission to see its contents.'


  showFileOperationUnsuccessfulError: ->

    new FilePermissionsModal
      title      : 'Operation Unsuccessful'
      contentText: 'Please ensure that you have write permission for this file and its folder.'


  showPermissionErrorOnOpeningFile: (err) ->

    if (err?.message?.indexOf 'permission denied') > -1
      helpers.showFileAccessDeniedError()
      return yes


  showPermissionErrorOnSavingFile: (err) ->

    if (err?.message?.indexOf 'permission denied') > -1
      helpers.showFileOperationUnsuccessfulError()
      return yes