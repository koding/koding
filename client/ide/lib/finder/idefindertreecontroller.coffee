kd = require 'kd'
FSHelper = require 'app/util/fs/fshelper'
NFinderTreeController = require 'finder/filetree/controllers/nfindertreecontroller'
IDEHelpers = require '../idehelpers'


module.exports = class IDEFinderTreeController extends NFinderTreeController

  cmCreateWorkspace: (node) -> @createWorkspace node


  cmCreateTerminal:  (node) -> @createTerminal  node


  createTerminal: (node) ->

    {path, machine} = node.getData()
    appManager      = kd.getSingleton 'appManager'
    path            = FSHelper.plainPath path

    appManager.tell 'IDE', 'createNewTerminal', { machine, path }


  collapseFolder: (nodeView, callback, silence) ->

    super nodeView, callback, silence

    return  if @dontEmitChangeEvent

    @emit 'FolderCollapsed', nodeView.getData().path


  expandFolder: (nodeView, callback, silence) ->

    super nodeView, callback, silence

    return  if @dontEmitChangeEvent

    @emit 'FolderExpanded', nodeView.getData().path


  deleteWorkspaceRootFolder: (machineUId, rootPath) ->

    node = @nodes["[#{machineUId}]#{rootPath}"]
    @deleteFiles [node] if node


  createWorkspace: (node) ->

    folder       = node.getData()
    name         = folder.name
    machineUId   = folder.machine.uid
    machineLabel = folder.machine.slug or folder.machine.label
    rootPath     = FSHelper.plainPath folder.path
    eventObj     = this
    options      = { name, machineUId, rootPath, machineLabel, eventObj }

    IDEHelpers.createWorkspace options

    {activitySidebar} = kd.singletons.mainView

    @once 'WorkspaceCreated', activitySidebar.bound 'addWorkspace'
