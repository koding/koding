class IDE.FinderTreeController extends NFinderTreeController


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

    appManager.tell 'IDE', 'createNewTerminal', machine, FSHelper.plainPath path
