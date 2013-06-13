## DEPRECATED DONT FORGET TO REMOVE IT
## NOT USED

class NFinderControllerOld extends KDViewController

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

    pathArray = (temp += "/#{chunk}" for chunk in path when chunk)

    pathArray.splice 0, 1 # getting rid of /home folder

    return pathArray

  resetInitialPath:->
    {nickname}  = KD.whoami().profile
    initialPath   = "/home/#{nickname}/Sites/#{nickname}.koding.com/website"
    @initialPath  = @expandInitialPath initialPath

  reset:->

    @appStorage = @getSingleton('mainController').getAppStorageSingleton 'Finder', '1.0'
    @appStorage.once "storageFetched", =>
      {nickname}    = KD.whoami().profile
      @mount        = FSHelper.createFile
        name        : nickname.toLowerCase()
        path        : "/home/#{nickname}"
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
        @resetInitialPath()  unless @initialPath
        recentFolders = @initialPath

      timer = Date.now()

      @mount.emit "fs.fetchContents.started"

      @utils.killWait kiteFailureTimer if kiteFailureTimer

      kiteFailureTimer = @utils.wait 5000, =>
        @treeController.notify "Couldn't fetch files! Click to retry", 'clickable', "Sorry, a problem occured while communicating with servers, please try again later.", yes
        @mount.emit "fs.fetchContents.finished"

        @treeController.once 'fs.retry.scheduled', =>
          @defaultStructureLoaded = no
          @loadDefaultStructure()

      if recentFolders.length is 0
        return log "recentFolders", recentFolders.length

      @multipleLs recentFolders, (err, response)=>
        if response
          files = FSHelper.parseLsOutput recentFolders, response
          @utils.killWait kiteFailureTimer
          @treeController.addNodes files
          @treeController.emit 'fs.retry.success'
          @treeController.hideNotification()


        log "#{(Date.now()-timer)/1000}sec !"
        # temp fix this doesn't fire in kitecontroller
        kiteController.emit "UserEnvironmentIsCreated"
        @mount.emit "fs.fetchContents.finished"

  multipleLs:(pathArray, callback)->

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
