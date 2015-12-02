kd                    = require 'kd'
remote                = require('app/remote').getInstance()
globals               = require 'globals'
FSHelper              = require 'app/util/fs/fshelper'
showError             = require 'app/util/showError'
dataProvider          = require 'app/userenvironmentdataprovider'
FilePermissionsModal  = require './views/modals/filepermissionsmodal'


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

    dataProvider.fetchMachineByUId machineUId, (m, workspaces) ->
      workspace = w for w in workspaces when w.rootPath is rootPath

      handleRoute = (machine, workspace) ->
        href = "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
        router.handleRoute href

      return handleRoute(machine, workspace) if workspace

      remote.api.JWorkspace.create data, (err, workspace) ->
        return helpers.handleWorkspaceCreateError_ eventObj, err  if err

        folderOptions  =
          type         : 'folder'
          path         : workspace.rootPath
          recursive    : yes
          samePathOnly : yes

        machine.fs.create folderOptions, (err, folder) ->
          return helpers.handleWorkspaceCreateError_ eventObj, err  if err

          filePath   = "#{workspace.rootPath}/README.md"

          kite = machine.getBaseKite()

          kite.init().then ->

            kite.fsUniquePath path: filePath

          .then (actualPath) ->

            readMeFile = FSHelper.createFileInstance { path: actualPath, machine }

            readMeFile.save WORKSPACE_WELCOME_TXT, (err) ->
              return helpers.handleWorkspaceCreateError_ eventObj, err  if err

              eventObj.emit 'WorkspaceCreated', workspace

              handleRoute(machine, workspace)


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


  updateWorkspace:(node, target) ->

    return unless node.options.type is 'folder' and node.machine

    searchPath = FSHelper.plainPath node.path
    targetPath = FSHelper.plainPath target if target

    dataProvider.fetchMachineByUId node.machine.uid, (machine, workspaces) =>

      callback = (err) =>

        return showError err, KodingError: "Couldn't update workspace." if err

        { mainView } = kd.singletons
        mainView.activitySidebar.updateMachines()


      updateWorkspace_ = (workspace) ->
        if target
          newPath = workspace.rootPath.replace searchPath, targetPath
          remote.api.JWorkspace.update workspace._id, { $set : { rootPath: newPath} }, callback
        else
          remote.api.JWorkspace.deleteById workspace._id, callback

      updateWorkspace_ w for w in workspaces when w.rootPath.indexOf(searchPath) > -1


  ###*
   * Clear snapshot and layout data of participants when participant is kicked
   * or leaved from a shared vm.
  ###
  deleteSnapshotData: (machine, nickname, callback = kd.noop) ->

    kite = machine.getBaseKite()

    dataProvider.fetchMachineByUId machine.uid, (m, workspaces) =>
      workspaces.forEach (ws) =>

        snapshotKey   = @getWorkspaceStorageKey ws, nickname
        layoutSizeKey = @getWorkspaceLayoutSizeStorageKey ws, nickname

        kite.storageDelete snapshotKey    # Remove snapshot
        kite.storageDelete layoutSizeKey  # Remove layout size data

      callback()


  getOpenedIDEInstancesByMachineUId: (machineUId) ->

    { appManager } = kd.singletons

    return appManager.getInstances('IDE')?.filter (instance) ->
      instance.mountedMachineUId is machineUId


  getWorkspaceStorageKey: (workspace, prefix) ->

    if prefix
      return "#{prefix}.wss.#{workspace.slug}"
    else
      return "wss.#{workspace.slug}"


  getWorkspaceLayoutSizeStorageKey: (workspace, username) ->

    return @getWorkspaceStorageKey workspace, "#{username}-LayoutSize"

