class NFinderController extends KDViewController

  constructor:(options = {}, data)->

    options.view = new KDView cssClass : "nfinder file-container"
    super options, data

    @kiteController = @getSingleton('kiteController')

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
      delegate          : @

    @treeController = new NFinderTreeController treeOptions, []
    
    @treeController.on "file.opened", (file)=> @setRecentFile file
    

  loadView:(mainView)->
    if KD.whoami() instanceof bongo.api.JAccount
      mainView.addSubView @treeController.getView()
    
      {nickname} = KD.whoami().profile
      mount      = FSHelper.createFile 
        name       : nickname
        # parentPath : "/"
        path       : "/Users/#{nickname}"
        type       : "mount"
      @treeController.initTree [mount]
      # setTimeout =>
      #   @treeController.expandFolder @treeController.nodes[mount.path], =>
      #     @treeController.expandFolder @treeController.nodes["#{mount.path}/public_html"], =>
      #       @treeController.expandFolder @treeController.nodes["#{mount.path}/public_html/#{nickname}.#{location.hostname}"], =>
      #         @treeController.expandFolder @treeController.nodes["#{mount.path}/public_html/#{nickname}.#{location.hostname}/httpdocs"]
      # , 2000

  
  getStorage: (callback) ->
    unless @_storage
      @_storage = 'in process'
      NFinderController.on 'storage.ready', callback
      appManager.getStorage 'Finder', '1.0', (error, storage) =>
        @_storage = storage
        NFinderController.emit 'storage.ready', storage
    else if @_storage is 'in process'
      NFinderController.on 'storage.ready', callback
    else
      callback @_storage

  setRecentFile:(file, callback)->

    @getStorage (storage)=>
      # recentFiles = storage.getAt('bucket.recentFiles') or []
      recentFiles = if storage.bucket?.recentFiles? then storage.bucket.recentFiles else []
      unless file.path in recentFiles
        recentFiles.pop() if recentFiles.length is @getOptions().maxRecentFiles
        recentFiles.unshift file.path
      else
        recentFiles.sort (path)-> if path is file.path then -1 else 0
      storage.update {
        $set: 'bucket.recentFiles': recentFiles
      }, callback
    