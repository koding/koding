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

    @kiteController = @getSingleton('kiteController')
    @treeController = new NFinderTreeController treeOptions, []

    if options.useStorage

      @treeController.on "file.opened", (file)=>
        @setRecentFile file.path

      @treeController.on "folder.expanded", (folder)=>
        @setRecentFolder folder.path

      @treeController.on "folder.collapsed", (folder)=>
        @unsetRecentFolder folder.path

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
      @appStorage.once "storageFetched", => @createRootStructure()
    else
      @createRootStructure()

  createRootStructure:->
    {nickname} = KD.whoami().profile
    @mount     = FSHelper.createFile
      name: nickname.toLowerCase()
      path: "/home/#{nickname}"
      type: "mount"

    @defaultStructureLoaded = no
    @treeController.initTree [@mount]
    @loadDefaultStructure()

  loadDefaultStructure:->

    return if @defaultStructureLoaded
    return unless KD.isLoggedIn()

    @defaultStructureLoaded = yes
    kiteController          = KD.getSingleton('kiteController')

    timer = Date.now()
    @mount.emit "fs.job.started"

    log "Calling readDirectory..."
    {nickname} = KD.whoami().profile
    kiteController.run
      method     : 'fs.readDirectory'
      withArgs   :
        onChange : (change)=>
          FSHelper.folderOnChange "/home/#{nickname}", change, @treeController
        path     : '.'
    , (err, response)=>
      @lastSuccessfulResponse?.stopWatching?()

      if response
        files = FSHelper.parseWatcher "/home/#{nickname}", response.files
        @treeController.addNodes files
        @treeController.emit 'fs.retry.success'
        @treeController.hideNotification()

        @lastSuccessfulResponse = response

      log "#{(Date.now()-timer)/1000}sec !"
      @mount.emit "fs.job.finished"

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
