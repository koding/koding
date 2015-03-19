remote = require('app/remote').getInstance()
showError = require 'app/util/showError'
kd = require 'kd'
globals = require 'globals'
FSHelper = require 'app/util/fs/fshelper'
FilePermissionsModal = require './views/modals/filepermissionsmodal'


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

        readMeFile.save globals.WORKSPACE_WELCOME_TXT, (err) =>
          return helpers.handleWorkspaceCreateError_ eventObj, err  if err

          eventObj.emit 'WorkspaceCreated', workspace

          href = "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
          router.handleRoute href


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