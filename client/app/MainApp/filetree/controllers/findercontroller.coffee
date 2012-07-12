class NFinderController extends KDViewController

  constructor:(options = {}, data)->

    options.view = new KDView cssClass : "nfinder file-container"
    super options, data

    @kiteController = @getSingleton('kiteController')
    {nickname} = KD.whoami().profile
    treeOptions =
      treeItemClass     : options.treeItemClass     or NFinderItem
      nodeIdPath        : options.nodeIdPath        or "path"
      nodeParentIdPath  : options.nodeParentIdPath  or "parentPath"
      dragdrop          : options.dragdrop           ? yes
      foldersOnly       : options.foldersOnly        ? no
      multipleSelection : options.multipleSelection  ? yes
      addOrphansToRoot  : options.addOrphansToRoot   ? no
      putDepthInfo      : options.putDepthInfo       ? yes
      contextMenu       : options.contextMenu        ? yes
      fsListeners       : options.fsListeners        ? no
      initialPath       : options.initialPath        ? "/Users/#{nickname}"
      maxRecentFolders  : options.maxRecentFolders  or 10
      delegate          : @

    @treeController = new NFinderTreeController treeOptions, []

    @defaultStructureLoaded = no

    @treeController.on "file.opened", (file)=> @setRecentFile file.path
    @treeController.on "folder.expanded", (folder)=> @setRecentFolder folder.path
    @treeController.on "folder.collapsed", (folder)=> @unsetRecentFolder folder.path

    @listenTo
      KDEventTypes       : "AppManagerOpensAnApplication"
      listenedToInstance : appManager
      callback           : (pubInst, appInst)=>
        if appInst instanceof StartTab12345 and not @defaultStructureLoaded
          @loadDefaultStructure()

    @loadDefaultStructureTimer = @utils.wait 5000, =>
      @loadDefaultStructure()

  loadView:(mainView)->

    mainView.addSubView @treeController.getView()

  reset:()->

    delete @_storage
    {initialPath} = @getOptions() # not used, fix this

    mount = if KD.isLoggedIn()
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
    @treeController.initTree [mount]

  loadDefaultStructure:->

    @defaultStructureLoaded = yes
    @utils.killWait @loadDefaultStructureTimer

    return unless KD.isLoggedIn()
    {nickname} = KD.whoami().profile

    @fetchStorage (storage)=>
      recentFolders = if storage.bucket?.recentFolders? and storage.bucket.recentFolders.length > 0
        storage.bucket.recentFolders
      else
        [
          "/Users/#{nickname}"
          "/Users/#{nickname}/Sites"
          "/Users/#{nickname}/Sites/#{nickname}.beta.koding.com"
          "/Users/#{nickname}/Sites/#{nickname}.beta.koding.com/website"
        ]

      timer = Date.now()
      mount = @treeController.nodes["/Users/#{nickname}"].getData()

      mount.emit "fs.fetchContents.started"
      KD.getSingleton('kiteController').run
        withArgs  :
          command : "ls #{recentFolders.join(" ")} -lpva --group-directories-first --time-style=full-iso"
      , (err, response)=>
        if response
          files = FSHelper.parseLsOutput recentFolders, response
          @treeController.addNodes files
        log "#{(Date.now()-timer)/1000}sec !"
        mount.emit "fs.fetchContents.finished"


  fetchStorage:(callback)->

    unless @_storage
      appManager.fetchStorage 'Finder', '1.0', (error, storage) =>
        callback @_storage = storage
    else
      callback @_storage

  setRecentFile:(filePath, callback)->

    @fetchStorage (storage)=>
      # recentFiles = storage.getAt('bucket.recentFiles') or []
      recentFiles = if storage.bucket?.recentFiles? then storage.bucket.recentFiles else []
      unless filePath in recentFiles
        recentFiles.pop() if recentFiles.length is @getOptions().maxRecentFiles
        recentFiles.unshift filePath

      storage.update {
        $set: 'bucket.recentFiles': recentFiles.slice(0,10)
      }, callback

  setRecentFolder:(folderPath, callback)->

    @fetchStorage (storage)=>

      recentFolders = if storage.bucket?.recentFolders? then storage.bucket.recentFolders else []

      unless folderPath in recentFolders
        recentFolders.push folderPath

      recentFolders.sort (path)-> if path is folderPath then -1 else 0

      storage.update {
        $set: 'bucket.recentFolders': recentFolders
      }, => #log "recentFolder set"

  unsetRecentFolder:(folderPath, callback)->

    @fetchStorage (storage)=>

      recentFolders = if storage.bucket?.recentFolders? then storage.bucket.recentFolders else []

      splicer = ->
        recentFolders.forEach (recentFolderPath)->
          if recentFolderPath.search(folderPath) > -1
            recentFolders.splice recentFolders.indexOf(recentFolderPath), 1
            splicer()
            return

      splicer()
      recentFolders.sort (path)-> if path is folderPath then -1 else 0

      storage.update {
        $set: 'bucket.recentFolders': recentFolders
      }, => #log "recentFolder unset"
