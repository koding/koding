class IDE.FinderTreeController extends NFinderTreeController

  cmCreateWorkspace: (node) -> @createWorkspace node


  createWorkspace: (node) ->
    folder       = node.getData()
    name         = folder.name
    machineUId   = folder.machine.uid
    machineLabel = folder.machine.label
    rootPath     = FSHelper.plainPath folder.path
    options      = { name, machineUId, rootPath, machineLabel }

    KD.getSingleton('mainView').activitySidebar.createNewWorkspace options
