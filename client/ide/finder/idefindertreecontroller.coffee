class IDE.FinderTreeController extends NFinderTreeController

  cmCreateWorkspace: (node) -> @createWorkspace node


  createWorkspace: (node) ->
    folder     = node.getData()
    name       = folder.name
    machineUId = folder.machine.uid
    rootPath   = FSHelper.plainPath folder.path
    options    = { name, machineUId, rootPath }

    KD.getSingleton('mainView').activitySidebar.createNewWorkspace options
