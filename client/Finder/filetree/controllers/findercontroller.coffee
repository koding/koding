class NFinderController extends KDViewController

  constructor:(options = {}, data)->

    options.view = new KDView cssClass : "nfinder file-container"

    treeOptions  = {}
    treeOptions.treeItemClass     = options.treeItemClass     or= NFinderItem
    treeOptions.nodeIdPath        = options.nodeIdPath        or= "path"
    treeOptions.nodeParentIdPath  = options.nodeParentIdPath  or= "parentPath"
    treeOptions.dragdrop          = options.dragdrop           ?= yes
    treeOptions.foldersOnly       = options.foldersOnly        ?= no
    treeOptions.hideDotFiles      = options.hideDotFiles       ?= no
    treeOptions.multipleSelection = options.multipleSelection  ?= yes
    treeOptions.addOrphansToRoot  = options.addOrphansToRoot   ?= no
    treeOptions.putDepthInfo      = options.putDepthInfo       ?= yes
    treeOptions.contextMenu       = options.contextMenu        ?= yes
    treeOptions.maxRecentFolders  = options.maxRecentFolders  or= 10
    treeOptions.useStorage        = options.useStorage         ?= no
    treeOptions.loadFilesOnInit   = options.loadFilesOnInit    ?= no
    treeOptions.delegate          = this

    super options, data


    TreeControllerClass = options.treeControllerClass or NFinderTreeController
    @treeController     = new TreeControllerClass treeOptions, []

    {appStorageController} = KD.singletons
    @appStorage = appStorageController.storage 'Finder', '2.0'

    @watchers = {}

    # this is here for when user login/register after opening Ace App
    # to refresh filetree
    mainController = KD.getSingleton("mainController")
    mainController.on "accountChanged.to.loggedIn", @bound 'reset'

    if options.useStorage

      @appStorage.ready =>

        @treeController.on "file.opened", @bound 'setRecentFile'

        @treeController.on "folder.expanded", (folder)=>
          @setRecentFolder folder.path

        @treeController.on "folder.collapsed", ({path})=>
          @unsetRecentFolder path
          @stopWatching path


    @noMachineFoundWidget = new NoMachinesFoundWidget
    @cleanup()

    # TODO ~ GG
    # vmc = KD.getSingleton("vmController")
    # vmc.on "StateChanged", @bound "checkVMState"
    # vmc.on "VMDestroyed",  @bound "unmountVm"


  loadView:(mainView)->

    mainView.addSubView @treeController.getView()
    mainView.addSubView @noMachineFoundWidget

    if @getOption 'loadFilesOnInit' then do @reset


  reset:->

    KD.singletons.computeController.ready =>

      if @getOption 'useStorage'
      then @appStorage.ready @bound 'loadMachines'
      else @utils.defer      @bound 'loadMachines'


  loadMachines:->

    { computeController } = KD.singletons

    computeController.fetchMachines (err, machines)=>

      unless KD.showError err
        if machines.length > 0
        then @mountMachines machines
        else @noMachineFoundWidget.show()


  mountMachine:(machine, fetchContent = yes)->

    unless machine.status.state is Machine.State.Running
      return warn "Machine '#{machine.getName()}' was not ready, I skipped it."

    { uid } = machine
    mRoots  = (@appStorage.getValue 'machineRoots') or {}
    path    = mRoots[uid] or "/"

    if @getMachineNode uid
      return warn "Machine #{machine.getName()} is already mounted!"

    @updateMountState uid, yes

    @machines.push FSHelper.createFileInstance
      name           : path
      path           : "[#{uid}]#{path}"
      type           : "machine"
      machine        : machine
      treeController : @treeController

    @noMachineFoundWidget.hide()

    machineItem = @treeController.addNode @machines.last

    if fetchContent and machineItem

      @utils.defer =>

        @treeController.expandFolder machineItem, (err)=>

          @treeController.selectNode machineItem

          @utils.defer =>
            if @getOptions().useStorage then @reloadPreviousState uid
        , yes


  mountMachines: (machines) ->

    do @cleanup
    for machine in machines
      @mountMachine machine


  unmountMachine: (uid)->

    machineItem = @getMachineNode uid
    return warn 'No such VM!'  unless machineItem

    @updateMountState uid, no
    @stopWatching machineItem.data.path
    FSHelper.unregisterVmFiles uid
    @treeController.removeNodeView machineItem
    @machines = @machines.filter (vmData)-> vmData isnt machineItem.data

    if @machines.length is 0
      @noMachineFoundWidget.show()
      @emit 'EnvironmentsTabRequested'

  updateMachineRoot:(uid, path, callback)->

    return warn 'Machine uid and new path required!'  unless uid or path

    @unmountMachine uid
    callback?()

    machineRoots = (@appStorage.getValue 'machineRoots') or {}
    machineRoots[uid] = path

    if @getOptions().useStorage
      @appStorage.setValue 'machineRoots', machineRoots

    { computeController } = KD.singletons

    computeController.fetchMachine uid, (err, machine)=>
      return KD.showError err  if err
      @mountMachine machine    if machine?


  setRecentFile:({path})->
    recentFiles = @appStorage.getValue('recentFiles')
    recentFiles = []  unless Array.isArray recentFiles

    unless path in recentFiles
      if recentFiles.length is @treeController.getOptions().maxRecentFiles
        recentFiles.pop()
      recentFiles.unshift path

    @appStorage.setValue 'recentFiles', recentFiles.slice(0,10), =>
      @emit 'recentfiles.updated', recentFiles

  hideDotFiles:(vmName)->
    return  unless vmName
    @setNodesHidden vmName, yes
    for own path, node of @treeController.nodes
      file = node.getData()
      if (file.vmName is vmName) and file.isHidden()
        @stopWatching file.path
        @treeController.removeNodeView node

  showDotFiles:(vmName)->
    return  unless vmName
    @setNodesHidden vmName, no
    for own path, node of @treeController.nodes when node.getData().type is 'vm'
      return if node.getData().vmName is vmName
        @treeController.collapseFolder node, =>
          @reloadPreviousState vmName
        , yes

  isNodesHiddenFor:(uid)->
    return yes  if @getOption 'hideDotFiles'
    return (@appStorage.getValue('machinesDotFileChoices') or {})[uid]

  setNodesHidden:(uid, state)->
    prefs = @appStorage.getValue('machinesDotFileChoices') or {}
    prefs[uid] = state
    @appStorage.setValue 'vmsDotFileChoices', prefs

  getRecentFolders:->
    recentFolders = @appStorage.getValue('recentFolders')
    recentFolders = []  unless Array.isArray recentFolders
    return recentFolders

  setRecentFolder:(folderPath, callback)->
    recentFolders = @getRecentFolders()
    unless folderPath in recentFolders
      recentFolders.push folderPath
    recentFolders.sort (path)-> if path is folderPath then -1 else 0
    @appStorage.setValue 'recentFolders', recentFolders, callback

  unsetRecentFolder:(folderPath, callback)->
    recentFolders = @getRecentFolders()
    recentFolders = recentFolders.filter (path)->
      path.indexOf(folderPath) isnt 0
    recentFolders.sort (path)->
      if path is folderPath then -1 else 0
    @appStorage.setValue 'recentFolders', recentFolders, callback

  expandFolder:(folderPath, callback=noop)->
    return  unless folderPath
    for own path, node of @treeController.nodes
      return @treeController.expandFolder node, callback  if path is folderPath
    callback {message:"Folder not exists: #{folderPath}"}

  expandFolders: (paths, callback=noop)->
    if typeof paths is 'string'
      paths = FSHelper.getPathHierarchy paths
    path = paths.pop()
    @expandFolder path, (err)=>
      @unsetRecentFolder path  if err
      if paths.length is 0
      then callback null, @treeController.nodes[path]
      else @expandFolders paths, callback

  reloadPreviousState:(uid)->
    recentFolders = @getRecentFolders()
    if uid
      recentFolders = recentFolders.filter (folder)->
        folder.indexOf "[#{uid}]" is 0
      if recentFolders.length is 0
        recentFolders = ["[#{uid}]/"]
    @expandFolders recentFolders

  uploadTo: (path)->
    {uploader, uploaderPlaceholder} = @getDelegate()
    uploader.setPath path
    uploaderPlaceholder.show()


  # Filetree helpers
  #
  getMachineNode:(uid)->

    return null  unless uid

    for own path, machineItem of @treeController.nodes
      if machineItem.data?.type is 'machine'
        return machineItem  if machineItem.data.uid is uid


  # Settings helpers
  #

  updateMountState:(uid, state)->

    return  if KD.isGuest()

    machines = @appStorage.getValue("mountedMachines") or {}
    machines[uid] = state

    @appStorage.setValue "mountedMachines", machines


  # FS Watcher helpers
  #

  registerWatcher:(path, stopWatching)->
    @watchers[path] = stop: stopWatching

  stopAllWatchers:->
    (watcher.stop() for own path, watcher of @watchers)
    @watchers = {}

  stopWatching:(pathToStop)->
    for own path, watcher of @watchers  when (path.indexOf pathToStop) is 0
      watcher.stop()
      delete @watchers[path]

  # Basics
  #

  cleanup:->
    @treeController.removeAllNodes()
    FSHelper.resetRegistry()
    @stopAllWatchers()
    @machines = []

