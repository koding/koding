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
    treeOptions.fsListeners       = options.fsListeners        ?= no
    treeOptions.initialPath       = options.initialPath        ?= "/Users/#{nickname}"
    treeOptions.maxRecentFolders  = options.maxRecentFolders  or= 10
    treeOptions.initDelay         = options.initDelay         or= 0
    treeOptions.useStorage        = options.useStorage         ?= no
    treeOptions.delegate          = @

    super options, data

    @kiteController = @getSingleton('kiteController')
    @appStorage     = @getSingleton('mainController').getAppStorageSingleton 'Finder', '1.0'

    @treeController = new NFinderTreeController treeOptions, []
    @treeController.on "file.opened", (file)=> @setRecentFile file.path
    @treeController.on "folder.expanded", (folder)=> @setRecentFolder folder.path
    @treeController.on "folder.collapsed", (folder)=> @unsetRecentFolder folder.path

  loadView:(mainView)->

    mainView.addSubView @treeController.getView()
    @reset()
    @viewLoaded = yes
    @utils.killWait @loadDefaultStructureTimer

    # temp hack, if page opens in develop section.
    @utils.wait 2500, =>
      @getSingleton("mainView").sidebar._windowDidResize()

  expandInitialPath:(path)->
    pathArray = []
    path      = path.split "/"
    temp      = ''

    for chunk in path
      pathArray.push temp+="/#{chunk}" if chunk

    pathArray.splice 0, 1
    pathArray

  reset:()->

    {initialPath} = @treeController.getOptions()
    @initialPath  = @expandInitialPath initialPath

    @mount = if KD.isLoggedIn()
      {nickname}    = KD.whoami().profile
      FSHelper.createFile
        name        : nickname
        path        : "/Users/#{nickname}"
        type        : "mount"
    else
      FSHelper.createFile
        name        : "guest"
        path        : "/Users/guest"
        type        : "mount"
    @defaultStructureLoaded = no
    @treeController.initTree [@mount]

    if @treeController.getOptions().useStorage
      unless @viewLoaded
        @loadDefaultStructureTimer = @utils.wait @treeController.getOptions().initDelay, =>
          @loadDefaultStructure()
      else
        @loadDefaultStructure()

  loadDefaultStructure:->

    return if @defaultStructureLoaded
    @defaultStructureLoaded = yes
    @utils.killWait @loadDefaultStructureTimer

    return unless KD.isLoggedIn()
    {nickname}     = KD.whoami().profile
    kiteController = KD.getSingleton('kiteController')
    @appStorage.fetchValue 'recentFolders', (recentFolders)=>

      unless Array.isArray recentFolders
        unless @initialPath
          {initialPath} = @treeController.getOptions()
          @initialPath  = @expandInitialPath initialPath
        recentFolders   = @initialPath

      timer = Date.now()

      @mount.emit "fs.fetchContents.started"

      @utils.killWait kiteFailureTimer if kiteFailureTimer

      kiteFailureTimer = @utils.wait 5000, =>
        @treeController.notify "Couldn't fetch files! Click to retry", 'clickable', "Sorry, a problem occured while communicating with servers, please try again later.", yes
        @mount.emit "fs.fetchContents.finished"

        @treeController.once 'fs.retry.scheduled', =>
          @defaultStructureLoaded = no
          @loadDefaultStructure()

      @multipleLs recentFolders, (err, response)=>
        if response
          files = FSHelper.parseLsOutput recentFolders, response
          @utils.killWait kiteFailureTimer
          @treeController.addNodes files
          @treecontroller?.emit 'fs.retry.success'

        log "#{(Date.now()-timer)/1000}sec !"
        # temp fix this doesn't fire in kitecontroller
        kiteController.emit "UserEnvironmentIsCreated"
        @mount.emit "fs.fetchContents.finished"

  multipleLs:(pathArray, callback)->

    return unless Array.isArray pathArray
    KD.getSingleton('kiteController').run
      withArgs  :
        command : "ls \"#{pathArray.join("\" \"")}\" -Llpva --group-directories-first --time-style=full-iso"
    , callback

  setRecentFile:(filePath, callback)->

    recentFiles = @appStorage.getValue('recentFiles')
    recentFiles = [] unless Array.isArray recentFiles

    unless filePath in recentFiles
      recentFiles.pop() if recentFiles.length is @treeController.getOptions().maxRecentFiles
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
