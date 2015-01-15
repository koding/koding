class FinderTreeController extends NFinderTreeController


  cmCreateWorkspace: (node) -> @createWorkspace node


  cmCreateTerminal:  (node) -> @createTerminal  node


  createWorkspace: (node) ->
    folder       = node.getData()
    name         = folder.name
    machineUId   = folder.machine.uid
    machineLabel = folder.machine.slug or folder.machine.label
    rootPath     = FSHelper.plainPath folder.path
    options      = { name, machineUId, rootPath, machineLabel }

    KD.getSingleton('mainView').activitySidebar.createNewWorkspace options


  createTerminal: (node) ->

    {path, machine} = node.getData()
    appManager      = KD.getSingleton 'appManager'
    path            = FSHelper.plainPath path

    appManager.tell 'IDE', 'createNewTerminal', { machine, path }


  collapseFolder: (nodeView, callback) ->

    super nodeView, callback

    return  if @dontEmitChangeEvent

    @emit 'FolderCollapsed', nodeView.getData().path


  expandFolder: (nodeView, callback) ->

    super nodeView, callback

    return  if @dontEmitChangeEvent

    @emit 'FolderExpanded', nodeView.getData().path


module.exports = FinderTreeController
