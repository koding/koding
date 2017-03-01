kd                     = require 'kd'
remote                 = require 'app/remote'
actions                = require 'app/flux/environment/actions'
FSHelper               = require 'app/util/fs/fshelper'
showError              = require 'app/util/showError'
actiontypes            = require 'app/flux/environment/actiontypes'
dataProvider           = require 'app/userenvironmentdataprovider'
FilePermissionsModal   = require './views/modals/filepermissionsmodal'
BannerNotificationView = require 'app/commonviews/bannernotificationview'


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
    { computeController, router, reactor } = kd.singletons

    # Create an object which has emit method.
    eventObj or= { emit: kd.noop }

    if not name or not machineUId
      err = { message: 'Missing options to create a new workspace' }
      return helpers.handleWorkspaceCreateError_ eventObj, err

    machine = computeController.findMachineFromMachineUId machineUId
    layout  = {}
    data    = { name, machineUId, machineLabel, rootPath, layout }

    unless machine
      err = { mesage: 'Machine not found.' }
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

            kite.fsUniquePath { path: filePath }

          .then (actualPath) ->

            readMeFile = FSHelper.createFileInstance { path: actualPath, machine }

            readMeFile.save WORKSPACE_WELCOME_TXT, (err) ->
              return helpers.handleWorkspaceCreateError_ eventObj, err  if err

              eventObj.emit 'WorkspaceCreated', workspace

              actions.createWorkspace machine, workspace
              actions.hideAddWorkspaceView machine._id

              dataProvider.fetch ->
                handleRoute(machine, workspace)


  handleWorkspaceCreateError_: (eventObj, error) ->

    eventObj.emit 'WorkspaceCreateFailed', error

    { reactor } = kd.singletons
    reactor.dispatch actiontypes.WORKSPACE_COULD_NOT_CREATE, error

    showError "Couldn't create your new workspace."
    kd.warn error


  showFileReadOnlyNotification: ->

    new FilePermissionsModal
      title      : 'Read-only file'
      contentText: 'This file is read-only. You won\'t be able to save your changes.'


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

    dataProvider.fetchMachineByUId node.machine.uid, (machine, workspaces) ->

      callback = (err) ->

        return kd.warn 'Failed to update workspace', err  if err

        { mainView } = kd.singletons
        mainView.activitySidebar.updateMachines()


      for w in workspaces when w.rootPath.indexOf(searchPath) > -1
        if target
          newPath = w.rootPath.replace searchPath, targetPath
          setData = { $set : { rootPath: newPath } }
          remote.api.JWorkspace.update w._id, setData, callback
        else
          remote.api.JWorkspace.deleteById w._id, callback


  showNotificationBanner: (options) ->

    options.cssClass    = kd.utils.curry 'ide-warning-view', options.cssClass
    options.click     or= kd.noop
    options.container or= kd.singletons.appManager.frontApp.mainView

    return new BannerNotificationView options
