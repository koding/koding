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

      @treeController.on "file.opened", (file)=>
        @setRecentFile file.path

      @treeController.on "folder.expanded", (folder)=>
        @setRecentFolder folder.path

      @treeController.on "folder.collapsed", ({path})=>
        @unsetRecentFolder path
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

  resetInitialPath:->
    {nickname}   = KD.whoami().profile
    initialPath  = "/Sites/#{nickname}.koding.com/website"
    @initialPath = @expandInitialPath initialPath

  reset:->
    if @getOptions().useStorage
      @appStorage = @getSingleton('mainController').\
                      getAppStorageSingleton 'Finder', '1.0'
      @appStorage.once "storageFetched", @bound 'loadVms'
    else
      @loadVms()

  loadDefaultStructure:->

    return unless KD.isLoggedIn()
    return if @defaultStructureLoaded
    @defaultStructureLoaded = yes

    kiteController = KD.getSingleton('kiteController')
    timer = Date.now()

    @vms.forEach (vmFs)->
      {treeController} = KD.getSingleton 'finderController'
      vmFs.emit "fs.job.started"
      kiteController.run
        method     : 'fs.readDirectory'
        vmName     : vmFs.vmName
        withArgs   :
          path     : FSHelper.plainPath vmFs.path
          onChange : (change)=>
            FSHelper.folderOnChange vmFs.vmName, vmFs.path, change, treeController
      , (err, response)=>

        if response
          vmFs.registerWatcher response
          files = FSHelper.parseWatcher vmFs.vmName, vmFs.path, response.files
          treeController.addNodes files
          treeController.emit 'fs.retry.success'
          treeController.hideNotification()

        log "#{(Date.now()-timer)/1000}sec !"
        vmFs.emit "fs.job.finished"

  loadVms:(vmNames, callback)->

    unless vmNames
      vmNames = [(KD.getSingleton 'vmController').getDefaultVmName()]

    return callback? "vmNames should be an Array"  unless Array.isArray vmNames

    @treeController.removeAllNodes()
    FSHelper.resetRegistry()
    @stopAllWatchers()

    @vms      = []
    _inUseVMs = []
    for vm in vmNames
      [vmName, path] = vm.split ":"
      path         or= "/home/#{KD.nick()}"
      unless vmName in _inUseVMs
        _inUseVMs.push vmName
        @vms.push FSHelper.createFile {
          name   : "#{path}"
          path   : "[#{vmName}]#{path}"
          type   : "vm"
          vmName : vmName
        }
      else warn "Ignoring already in use VM, named #{vmName}"

    @defaultStructureLoaded = no
    @treeController.initTree @vms
    @loadDefaultStructure()
    callback?()

  updateVMRoot:(vmName, path, callback)->
    # I know this looks ugly, I'll make it better later ~ GG
    newVms = []
    for vm in @vms
      if vm.vmName is vmName
      then newPath = path
      else newPath = FSHelper.plainPath vm.path
      newVms.push "#{vm.vmName}:#{newPath}"
    @loadVms newVms, callback

  setRecentFile:(filePath, callback)->

    recentFiles = @appStorage.getValue('recentFiles')
    recentFiles = [] unless Array.isArray recentFiles

    unless filePath in recentFiles
      if recentFiles.length is @treeController.getOptions().maxRecentFiles
        recentFiles.pop()
      recentFiles.unshift filePath

    @appStorage.setValue 'recentFiles', recentFiles.slice(0,10), =>
      @emit 'recentfiles.updated', recentFiles

  setRecentFolder:(folderPath, callback)->

    recentFolders = @appStorage.getValue('recentFolders')
    recentFolders = [] unless Array.isArray recentFolders

    unless folderPath in recentFolders
      recentFolders.push folderPath

    recentFolders.sort (path)-> if path is folderPath then -1 else 0

    @appStorage.setValue 'recentFolders', recentFolders, callback

  unsetRecentFolder:(folderPath, callback)->

    recentFolders = @appStorage.getValue('recentFolders')
    recentFolders = [] unless Array.isArray recentFolders

    splicer = ->
      recentFolders.forEach (recentFolderPath)->
        if recentFolderPath.search(folderPath) > -1
          recentFolders.splice recentFolders.indexOf(recentFolderPath), 1
          splicer()
          return
    splicer()

    recentFolders.sort (path)-> if path is folderPath then -1 else 0
    @appStorage.setValue 'recentFolders', recentFolders, callback
