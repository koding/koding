class NFinderController extends KDViewController

  constructor:(options = {}, data)->

    {nickname}  = KD.whoami().profile

    options.view = new KDView cssClass : "nfinder file-container"
    treeOptions  = {}
    treeOptions.treeItemClass     = options.treeItemClass     or= NFinderItem
    treeOptions.nodeIdPath        = options.nodeIdPath        or= "path"
    treeOptions.nodeParentIdPath  = options.nodeParentIdPath  or= "parentPath"
    treeOptions.dragdrop          = options.dragdrop           ?= yes
    treeOptions.foldersOnly       = options.foldersOnly        ?= no
    treeOptions.multipleSelection = options.multipleSelection  ?= yes
    treeOptions.addOrphansToRoot  = options.addOrphansToRoot   ?= no
    treeOptions.putDepthInfo      = options.putDepthInfo       ?= yes
    treeOptions.contextMenu       = options.contextMenu        ?= yes
    treeOptions.maxRecentFolders  = options.maxRecentFolders  or= 10
    treeOptions.useStorage        = options.useStorage         ?= no
    treeOptions.loadFilesOnInit   = options.loadFilesOnInit    ?= no
    treeOptions.delegate          = @

    super options, data

    @treeController = new NFinderTreeController treeOptions, []

    if options.useStorage

      @treeController.on "file.opened", @bound 'setRecentFile'

      # @treeController.on "folder.expanded", (folder)=>
      #   @setRecentFolder folder.path

      @treeController.on "folder.collapsed", ({path})=>
        # @unsetRecentFolder path
        @stopWatching path

  watchers: {}

  registerWatcher:(path, stopWatching)->
    @watchers[path] = stop: stopWatching

  stopAllWatchers:->
    (watcher.stop() for path, watcher of @watchers)
    @watchers = {}

  stopWatching:(pathToStop)->
    for path, watcher of @watchers  when (path.indexOf pathToStop) is 0
      watcher.stop()
      delete @watchers[path]

  loadView:(mainView)->

    mainView.addSubView @treeController.getView()
    @viewLoaded = yes

    @reset()  if @getOptions().loadFilesOnInit

    # temp hack, if page opens in develop section.
    @utils.wait 2500, =>
      @getSingleton("mainView").sidebar._windowDidResize()

  reset:->
    if @getOptions().useStorage
      @appStorage = @getSingleton('mainController').\
                      getAppStorageSingleton 'Finder', '1.0'
      @appStorage.once "storageFetched", @bound 'loadVms'
    else
      @loadVms()

  loadVms:(vmNames, callback)->
    mountVms = (vms)=>
      unless Array.isArray vms
        return callback? "vmNames should be an Array"
      @cleanup()
      @mountVm vm  for vm in vms
      callback?()

    if vmNames then mountVms vmNames
    else KD.remote.api.JVM.fetchVmsByContext {}, (err, vms)->
      return callback? err  if err
      if not vms or vms.length is 0
        vms = [(KD.getSingleton 'vmController').getDefaultVmName()]
      mountVms vms

  getVmNode:(vmName)->
    return null  unless vmName
    for path, vmItem of @treeController.nodes  when vmItem.data?.type is 'vm'
      return vmItem  if vmItem.data.vmName is vmName

  mountVm:(vm, fetchContent = yes)->
    return unless KD.isLoggedIn()
    return warn 'VM path required! e.g VMNAME[:PATH]'  unless vm

    [vmName, path] = vm.split ":"
    path or= "/home/#{KD.nick()}"

    if vmItem = @getVmNode vmName
      return warn "VM #{vmName} is already mounted!"

    @vms.push FSHelper.createFile
      name   : "#{path}"
      path   : "[#{vmName}]#{path}"
      type   : "vm"
      vmName : vmName

    @treeController.addNode @vms.last

    vmItem = @getVmNode vmName
    @treeController.expandFolder vmItem  if fetchContent and vmItem

  unmountVm:(vmName)->
    return unless KD.isLoggedIn()
    return warn 'No such VM!'  unless vmItem = @getVmNode vmName

    if vmItem
      @stopWatching vmItem.data.path
      FSHelper.deregisterVmFiles vmName
      @treeController.removeNodeView vmItem
      @vms = @vms.filter (vmData)-> vmData isnt vmItem.data

  updateVMRoot:(vmName, path, callback)->
    return warn 'VM name and new path required!'  unless vmName or path

    @unmountVm vmName
    callback?()
    @mountVm "#{vmName}:#{path}"

  cleanup:->
    @treeController.removeAllNodes()
    FSHelper.resetRegistry()
    @stopAllWatchers()
    @vms = []

  setRecentFile:({path})->

    recentFiles = @appStorage.getValue('recentFiles')
    recentFiles = [] unless Array.isArray recentFiles

    unless path in recentFiles
      if recentFiles.length is @treeController.getOptions().maxRecentFiles
        recentFiles.pop()
      recentFiles.unshift path

    @appStorage.setValue 'recentFiles', recentFiles.slice(0,10), =>
      @emit 'recentfiles.updated', recentFiles

  # FIXME Recent Folders support ~ GG

  # setRecentFolder:(folderPath, callback)->
  #   recentFolders = @appStorage.getValue('recentFolders')
  #   recentFolders = [] unless Array.isArray recentFolders
  #   unless folderPath in recentFolders
  #     recentFolders.push folderPath
  #   recentFolders.sort (path)-> if path is folderPath then -1 else 0
  #   @appStorage.setValue 'recentFolders', recentFolders, callback

  # unsetRecentFolder:(folderPath, callback)->
  #   recentFolders = @appStorage.getValue('recentFolders')
  #   recentFolders = [] unless Array.isArray recentFolders
  #   splicer = ->
  #     recentFolders.forEach (recentFolderPath)->
  #       if recentFolderPath.search(folderPath) > -1
  #         recentFolders.splice recentFolders.indexOf(recentFolderPath), 1
  #         splicer()
  #         return
  #   splicer()
  #   recentFolders.sort (path)-> if path is folderPath then -1 else 0
  #   @appStorage.setValue 'recentFolders', recentFolders, callback
