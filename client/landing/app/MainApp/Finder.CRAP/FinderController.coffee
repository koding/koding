class FinderController extends KDTreeViewController
  
  systemFoldersRegExp = 
    ///
    ^\.cagefs
    ///
  
  removeSystemFilesFromData = (rawItems)->
    items = []
    for item in rawItems
      unless systemFoldersRegExp.test item.name
        items.push item
    return items

  constructor:(options = {},data)->
    options.view or= new Finder
      type      : "filetree"
      domId     : "finder"
      cssClass  : "file-container"
    options.maxRecentFiles ?= 10
    super options,data
    @fs       = KD.getSingleton "fs"
    @command  = new Command
    @_storage = no
    @addListeners()
    
  addListeners:()->
    kiteController = @getSingleton("kiteController")
    # kiteController.registerListener
    #   KDEventTypes  : "NoSuchUser"
    #   listener      : @
    #   callback      : (pubInst,error)=>
    #     log "hey i am here"

    if kiteController.status
      @start()
    else
      kiteController.registerListenOncer
        KDEventTypes : "SharedHostingIsReady"
        listener     : @
        callback     : @start

    finder = @
    
    @listenTo
      KDEventTypes        : [ className:"KDView", eventType : "mousedown" ]
      callback            : @mouseDownOnKDView
    @listenTo
      KDEventTypes        : [eventType : "FileChanged"]
      callback            : @fileChanged
      
    setTimeout => #quick hack, fs object is not yet there
      @setFsListeners()
    , 100

  start:->
    # log "Do we start???",@getSingleton("kiteController").status
    @fs.reset()
    account = KD.whoami()
    account.getDefaultEnvironment (defaultEnvironment, err)=>
      if err then log err
      else
        # @_commander.setEnvironment defaultEnvironment
        @setEnvironment defaultEnvironment
        appManager.setEnvironment defaultEnvironment
          

  getEnvironment:()->
    @environment
    
  getStorage: (callback) ->
    unless @_storage
      @_storage = 'in process'
      FinderController.on 'storage.ready', callback
      appManager.getStorage 'Finder', '1.0', (error, storage) =>
        @_storage = storage
        FinderController.emit 'storage.ready', storage
    else if @_storage is 'in process'
      FinderController.on 'storage.ready', callback
    else
      callback @_storage

  setView:(aViewInstance)->
    super
    aViewInstance.registerListener KDEventTypes : ['keydown'], callback : @keyDownOnFinder, listener : @
    aViewInstance.registerListener KDEventTypes : ['ItemDidExpand'], listener : @, callback : @itemExpanded
  
  initiate: (mounts) ->
    treeItemsData = @convertFinderDataToKDTreeViewData mounts
    parentItems = @instantiateItems treeItemsData, yes
    
    # initiator = (folder) =>
    #   return unless folder.subItems
    #   newItems    = @convertFinderDataToKDTreeViewData folder.subItems
    #   return if newItems.length is 0
    #   parentView  = @itemForId newItems[0].parentId
    # 
    #   @addSubItemsOfItems [parentView], newItems
      
      # for item in folder.subItems
      #   if item.isFolder()
      #     initiator item
      
    # initiator treeItemsData[0]
    
    # if parentItems[0]
    #   parentItems[0].getData().list =>
    #     @getStorage (storage) =>
    #       if storage
    #         state = storage.bucket[parentItems[0].getData().path]
    #         if state is 'opened'
    #           @expandFolder parentItems[0]
  
  setEnvironment:(environment)->
    controller    = @
    window.environment = @environment  = environment
    if environment
      environment.getMountedDisks (mounts, err)=>
        if err then warn err
        else
          controller.removeAllItems()
          @initiate mounts
  
  addMount:(publishingInstance, {data})->
    mount = data
    @getEnvironment().accessMount mount, ()->
      log arguments
  
  getCommand:-> @command
  
  saveFileContents:(appController,data)=>
    {file, newContent, callback} = data
    dirtyFile = $.extend {}, file, contents:newContent
    oldContent = file.contents
    if dirtyFile.id
      file.contents = newContent
      # path = (@pathForItemData dirtyFile) #we cant use that, there is a chance that items is not yet rendered
      path = file.path
      @getCommand().emit "fs.saveFile.start", file:file, oldFile: file, oldContent:oldContent, newFile: dirtyFile, path : path, callback: callback
    else
      @addNewItem {}, file
      
      $.extend file, dirtyFile
      # path = (@pathForItemData file)
      path = file.path
      @getCommand().emit "fs.saveFile.start", file:file, oldContent:oldContent, oldFile: dirtyFile, createMode:yes, newFile: dirtyFile, path : path, callback: callback

  fileChanged: (appController, data) ->
    {file, changed} = data
    return unless file.id
    item = @itemForId file.id
    item.changed changed if item

  convertFinderDataToKDTreeViewData:(newItemsData = [])->
    newItemsData = removeSystemFilesFromData newItemsData if newItemsData.length
    data = for itemData, index in newItemsData
      unless itemData instanceof KDEventEmitter
        itemData = @fs.create itemData

      [parentPathArray..., name] = itemData.path.split('/')
      itemData.parentId = @traverseTreeByPath parentPathArray
      unless itemData.parentId
        itemData.parentPath = itemData.path.replace(/(.*)(\/.*?$)/, '$1')
      itemData
    return data

  itemExpanded:(publishingInstance, folder)=>
    # log "itemExpanded >>>>>>", folder
    controller = @
    if folder.needsSubItemsRefresh
      # folder.getData().list()
      folder.getData().list =>
        @expandFolder folder
      # subItems = @getOrderedSubItems folder
      # subFoldersThatNeedRefresh = (item for item in subItems when item.getData().type is 'folder' or item.getData().type is 'mount')
      # treeItemsData = (@getOrderedItemsData subFoldersThatNeedRefresh)
      # log 'going to list', treeItemsData, folder
      # for item in treeItemsData
      #   item.list()
      
      
      # if subFoldersThatNeedRefresh.length > 0
      #   parentPaths = for parentItem in subFoldersThatNeedRefresh
      #     @pathForItem parentItem
      #   @getCommand().emit "fs.multiLs.start", {views: subFoldersThatNeedRefresh, dataItems: treeItemsData, paths:parentPaths, folder}
          
  refreshFolder: (folder, callback) ->
    folder.getData().refresh()
    # @removeSubItemsOfItem folder
    # @getCommand().emit 'fs.multiLs.start', {views: [folder], dataItems: [folder.getData()], paths:[@pathForItem folder], folder, callback}
    
  addNewItem: (item) ->
    [newItemData] = @convertFinderDataToKDTreeViewData [item]
    if newItemData?
      parentView = @itemForId newItemData.parentId
      @addSubItemsOfItems [parentView], [newItemData]
    # else
    #   state = "unknown"

    # @getStorage (storage) =>
    #   if storage
    #     state or= storage.getOption newItemData.path
    #     if state is 'opened'
    #       view = @itemForId newItemData.id
    #       if view
    #         @getView().propagateEvent KDEventType : 'ItemDidExpand', globalEvent : yes, view

  keyDownOnFinder:(publishingInstance,event)->
    if event.shiftKey and event.metaKey and event.which is 83 # S key
      @showGlobalSearch()
      return
    
    if event.altKey
      switch event.which
        when 40 # down key
          item = @selectedItems[0]
          @createContextMenu item, event
      return

    switch event.which
      when 8
        @removeSelectedFiles()
      when 13 then @performEnter event
      when 27
        if @_currentDragHelper    # cancel drag if there is one
          mouseUpEvent              = $.Event 'mouseup'
          mouseUpEvent.cancelDrop   = yes
          @_currentDragHelper.trigger mouseUpEvent
          delete @_currentDragHelper
          
        @cancelInlineEditors event
      when 37 then @goLeft event
      when 38 then @goUp event
      when 39 then @goRight event
      when 40 then @goDown event
      
  showGlobalSearch: ->
    unless @_globalSearch
      @_globalSearch = new FinderGlobalSearch
        title: 'Global Search'
        delegate: @
        fx: yes
        
    @_globalSearch.show()

  removeSelectedFiles: ->
    if @selectedItems.length is 1
      item = @selectedItems[0]
      item.performRemove()
      @remove item
      @makeItemSelected item
    else
      @getView().deleteDialog @selectedItems, (remove) =>
        if remove
          for item in @selectedItems.slice 0
            @_remove item
          
  makeItemSelectedByData:(data)->
    for fileItem in @itemsOrdered
      if fileItem.getData() is data
        return @makeItemSelected fileItem

  makeItemSelected:(publishingInstance, event)->
    return unless publishingInstance?
    if publishingInstance instanceof KDTreeItemView
      if event?.metaKey
        publishingInstance.setSelected()
        publishingInstance.highlight()
        # @saveSelected publishingInstance
        @lastSelected = [publishingInstance]
        @propagateEvent KDEventType : "ItemSelectedEvent", publishingInstance
        @selectedItems.push publishingInstance
        
      else if event?.shiftKey
        @lastSelected = [publishingInstance] unless @lastSelected?
        (@selectedItems.splice (@selectedItems.indexOf lastSelected), 1 while (@selectedItems.indexOf lastSelected) isnt -1) for lastSelected in @lastSelected
        @lastSelected = @lastSelected[0]
        
        if (firstIndex = @itemsOrdered.indexOf @lastSelected) < (lastIndex = @itemsOrdered.indexOf publishingInstance)
          @lastSelected = @itemsOrdered[firstIndex..lastIndex]
        else
          @lastSelected = @itemsOrdered[lastIndex..firstIndex].reverse()
        
        @selectedItems = @selectedItems.concat @lastSelected
        for newSelection in @lastSelected
          @propagateEvent KDEventType : "ItemSelectedEvent", newSelection
          newSelection.setSelected()
          newSelection.highlight()
          # @saveSelected newSelection
        
      else
        publishingInstance.setSelected()
        publishingInstance.highlight()
        # @saveSelected publishingInstance
        @lastSelected = [publishingInstance]
        @propagateEvent KDEventType : "ItemSelectedEvent", publishingInstance
        @selectedItems = [publishingInstance]
        
      @undimSelection()
      @unselectAllExceptJustSelected()
      
      @getView().mouseDown() # setting keyview for keyboard control
      @lastSelectedByKey = @lastSelected[-1..][0]
    else
      warn "FIX: ",publishingInstance, "is not a KDTreeItemView, check event listeners!"
      
  setFsListeners: ->
    compressFinish = ({error}) ->
      if error
        new FsErrorNotificationView
          title: "Couldn't compress files"
          description: error
          
    makePublicCallback = ({error, url}) ->
      if error
        new FsErrorNotificationView
          title: "Couldn't donwload files"
          description: error
      else
        log 'got url', url
        new FinderDownloadIFrame {url}
    
    eventsMap = 
      'compress.finish'     : compressFinish
      'makePublic.finish'   : makePublicCallback
    
    for eventName, callback of eventsMap
      @fs.on eventName, callback
    
    @getView().on 'destroy', =>
      for eventName, callback of eventsMap
        @fs.unsubscribe eventName, callback
      
      for index, item of @itemsIndexed # clean up
        item.destroy()
      
  setDataListeners: (itemInstance) ->
    if itemInstance instanceof MountItemView or itemInstance instanceof FolderItemView
      itemInstance.listenTo
        KDEventTypes: 'ViewAppended'
        listenedToInstance: itemInstance
        callback: =>
          itemAppear = (item) =>
            @addNewItem item
            
            # @getStorage (storage) =>
            #   if storage
            #     state = storage.bucket[item.path]
            #     if state is 'opened'
            #       item.list =>
            #         view = @itemForId item.id
            #         @getView().expandOrCollapseItem view if view
            
          itemInstance.getData().onNewItem itemAppear

            
          # itemInstance.on 'destroy', -> #cleaning up our listeners
          #   itemInstance.getData().storyEmitter.unsubscribe 'item.appear', itemAppear
            
    removeStartListener = ->
      itemInstance.$().hide()
      
    removeFinishListener = ({error}) =>
      if error
        new FsErrorNotificationView
          title: "Couldn't delete file"
          content : "click for details..."
          description: error
          
        @cancelDelete itemInstance
        itemInstance.$().show()
      else
        @removeItem itemInstance
        
    itemDisappearListener = =>
      view = @itemForData itemInstance.getData()
      if view # view do not exist anymore in this finder
        @removeItem itemInstance
      else
        itemInstance.destroy()
      
    moveFinishListener = ({error}) =>
      if error
        new FsErrorNotificationView
          title: "Couldn't move file #{itemInstance.getData().name}"
          description: error
          
    renameFinishedListener = ({error}) =>
      if error
        new FsErrorNotificationView
          title: "Couldn't rename file #{itemInstance.getData().name}"
          description: error
      else
        itemInstance.render()
        
    createFolderListener = ({error, folder}) =>
      @makeItemSelectedByData folder
      if error
        new FsErrorNotificationView
          title: "Couldn't create folder"
          description: error
          
    createFileListener = ({error, file}) =>
      @makeItemSelectedByData file
      if error
        new FsErrorNotificationView
          title: "Couldn't create file"
          description: error
            
    listenersMap =
      'remove.start'          : removeStartListener
      'remove.finish'         : removeFinishListener
      'item.disappear'        : itemDisappearListener
      'move.finish'           : moveFinishListener
      'rename.finish'         : renameFinishedListener
      'file.create.finish'    : createFileListener
      'folder.create.finish'  : createFolderListener
      
    for eventName, callback of listenersMap
      itemInstance.getData().on eventName, callback
    
    itemInstance.on 'destroy', -> #cleaning up our listeners
      for eventName, callback of listenersMap
        itemInstance.getData().unsubscribe eventName, callback

    
  itemClass: (options, dataEmitter) ->
    itemData = dataEmitter.getData()
    itemInstance = @archivedItems[itemData.path]
    if not itemInstance? or reloadAll
      if (itemData.name.charAt 0) is '.'
        hiderClass = if (localStorage.hiddenFiles) is 'hidden' then 'hideable hidden' else 'hideable'
      
      switch itemData.type
        when "mount"
          if (itemData.name.charAt 0) is '.'
            hiderClass = if (localStorage.hiddenFiles) is 'hidden' then 'mount-item-view kdtreeitemview hideable hidden' else 'mount-item-view kdtreeitemview hideable'
          itemInstance = new MountItemView  {type:"mount", delegate : @getView(), cssClass: hiderClass}, dataEmitter
        when "folder"   then itemInstance = new FolderItemView  {type:"folder", delegate : @getView(), cssClass: hiderClass}, dataEmitter
        when "symLink"  then itemInstance = new FileItemView    {type:"file",   delegate : @getView(), cssClass: hiderClass}, dataEmitter
        when "section"  then itemInstance = new SectionTitle    {type:"section",delegate : @getView(), cssClass: hiderClass}, dataEmitter
        else itemInstance = new FileItemView    {type:"file",   delegate : @getView(), cssClass: hiderClass}, dataEmitter
        
      @setDataListeners itemInstance


      @listenTo
        KDEventTypes        : ["mousedown","contextmenu"]
        listenedToInstance: itemInstance
        callback            : @itemClicked
      @listenTo
        KDEventTypes        : ["dblclick"]
        listenedToInstance: itemInstance
        callback            : @doubleClick
      
      itemInstance.registerListener KDEventTypes:'contextmenu', callback:@createContextMenu, listener:@
      itemInstance.registerListener KDEventTypes:'permissionsChange', callback:@setPermissions, listener:@
      itemInstance.registerListener KDEventTypes:'permissionsFetch', callback:@fetchPermissions, listener:@
      # itemInstance.registerListener KDEventTypes:'highlightRemoved', callback:@cancelAllEditings, listener:@
      itemInstance.registerListener KDEventTypes:'highlightRemoved', callback:@submitAllEditings, listener:@
      
      if itemInstance.isDraggable()
        itemInstance.setDragDelegate @
        itemInstance.setDropDelegate @

    # cutOf = (itemInstance) ->
    #       $title      = itemInstance.$('.title:first')
    #       width       = itemInstance.getWidth()
    #       titleWidth  = $title.width()
    #       titleLeft   = $title.position().left
    #       unless itemInstance.$titleClone
    #         $titleClone = $title.clone()
    #         itemInstance.$titleClone = $titleClone
    #         $titleClone.css display: 'none'
    #         itemInstance.$('.finder-item').append $titleClone
    #       else
    #         $titleClone = itemInstance.$titleClone
    #       
    #       getCropped = (len) ->
    #         title = itemInstance.getData().title
    #         if len is 0
    #           title
    #         else
    #           newTitle = ''
    #           newTitle += title.substr 0, (title.length / 2) - (len/2)
    #           newTitle += '...'
    #           newTitle += title.substr (title.length / 2) + (len/2), title.length
    #           
    #           # itemInstance.getData().title.substr 0, itemInstance.getData().title.length - len
    #       
    #       cropTo = (width, crop = 0) ->
    #         checkNewTitle = getCropped crop
    #         $titleClone.html checkNewTitle
    #         titleCloneWidth = $titleClone.width()
    #         return if titleCloneWidth is 0 or width is 0
    # 
    #         if titleCloneWidth < width
    #           $title.html checkNewTitle
    #         else
    #           cropTo width, crop + 1
    # 
    #       setTimeout -> #giving browser some time to think
    #         cropTo width - titleLeft
    #       , 0
        
    itemInstance.listenTo
      KDEventTypes: 'FinderResized'
      listenedToInstance: @
      callback: (pb, event) ->
        clearTimeout itemInstance.__resizeTimeout
        itemInstance.__resizeTimeout = setTimeout ->
          itemInstance.checkTitleSize()#protecting from firing too many times
          # cutOf itemInstance 
        , 25

    itemInstance
    

  itemWithPath:(path)->
    @itemForId @traverseTreeByPath path.split "/"
  
  pathForItemData:(item)->
    pathFromBase = (@treePathArrayForId 'name', item.id).join '/'
    basePath = (@baseItem item).parentPath
    "#{basePath}/#{pathFromBase}"
  
  pathForItem:(item)->
    pathFromBase = (@treePathArrayForId 'name', item.getData().id).join '/'
    basePath = (@baseItem item.getData()).parentPath
    "#{basePath}/#{pathFromBase}"
  
  traverseTreeByPath:(pathArray)->
    for own id, item of @itemsStructured.items
      basePath = new RegExp "^(#{(@baseItem item.getData()).parentPath}/)"
      pathFromBase = (pathArray.join '/').replace basePath, ''
      break if pathFromBase isnt ""
    @traverseTreeByProperty 'name', (pathFromBase?.split '/') or []

  nearestFolder:(itemData)->
    itemData = itemData[0] if $.isArray itemData
    type = itemData.type
    return @itemForData itemData if type is "mount" or type is "folder" or type is "section"
    return @itemForId itemData.parentId

  itemMouseDownIsReceived:(publishingInstance,event)->
    switch event.type
      when "dblclick" then @doubleClick publishingInstance,event
      when "mousedown"
        switch event.which
          when 1 then @leftClick publishingInstance,event
          when 3 then @rightClick publishingInstance,event

  doubleClick:(publishingInstance,event)->
    # clearTimeout @_canRenameTimerStart
    # clearTimeout @_canRenameTimerStop
    # @_canRename = no

    switch publishingInstance.getOptions().type
      when "mount" then @expandOrCollapseFolder publishingInstance,event
      when "folder"
        unless publishingInstance.inlineEdit
          @expandOrCollapseFolder publishingInstance,event
      when "file" 
        unless publishingInstance.inlineEdit
          @openFile publishingInstance,event
      when "section"  then @expandSection publishingInstance,event

  performEnter:(publishingInstance,event)=>
    item = @selectedItems[0]
    unless item.deleteContainer
      switch item.getOptions().type
        when "mount", "folder","section" then @goRight item,event
        when "file" then @openFile item,event
    else
      @_remove item

  goLeft:(event)->
    item = @selectedItems[0]
    if item.getData().type isnt "file" and item.expanded
      @expandOrCollapseFolder item
    else
      @makeItemSelected @getParentItem forItem:item

  goRight:(event)->
    item = @selectedItems[0]
    if item.getData().type isnt "file" and not item.expanded
      @expandOrCollapseFolder item

  goUp:(event)->
    currentOrderedIndex = @orderedIndex @lastSelectedByKey.getData().id
    @selectNextVisibleItem currentOrderedIndex,-1, event
    @getView().makeScrollIfNecessary @selectedItems[0]

  goDown:(event)->
    currentOrderedIndex = @orderedIndex @lastSelectedByKey.getData().id
    @selectNextVisibleItem currentOrderedIndex,1, event
    @getView().makeScrollIfNecessary @selectedItems[0]
    
  # saveSelected: (item) ->
  #   @storage.set 'selectedPath', @pathForItem item
  #   
  # restoreSelected: ->
  #   path = @storage.get 'selectedPath'
  #   @makeItemSelected (@itemWithPath path), null

  # _expandOrCollapseFolder: (item)->
  #   if not item.expanded
  #     item.waitingToExpand = yes
  #   else
  #     item.waitingToExpand = no
  #     
  #   @getView().expandOrCollapseItem item
  
  expandOrCollapseFolder:(item)->
    @getView().expandOrCollapseItem item
    # @_expandOrCollapseFolder item
    # state = no
    # if item.expanded? and item.expanded
    #   state = 'opened'
    
    # put this back when watcher is working again - sinan 04/25/12
    # if state
    #   FS.watch dir: item.getData().path
    # else
    #   FS.unwatch dir: item.getData().path

    # @getStorage (storage) ->
    #   if storage
    #     if state is 'opened'
    #       storage.setOption item.getData().path, 'opened'
    #     else
    #       storage.dropOption item.getData().path
        
    # expandedFolders = @storage.get('expandedFolders', [])
    # if item.expanded? and item.expanded
    #   expandedFolders.push item.getData().path
    # else
    #   index = expandedFolders.indexOf item.getData().path
    #   if index > -1
    #     expandedFolders.splice index, 1
    #   
    # @storage.set 'expandedFolders', expandedFolders
      
  cancelInlineEditors: (event) ->
    for itemView in @itemsOrdered.slice 0
      @cancelAllEditings itemView
    
  cancelAllEditings:(itemView)->
    @cancelRename(itemView)
    @cancelDelete(itemView)
    
  submitAllEditings: (itemView) ->
    @submitRename itemView
    
  submitRename: (itemView) ->
    if itemView.inlineEdit
      #hack, fires too many times
      clearTimeout itemView._submitTimer
      itemView._submitTimer = setTimeout ->
        delete itemView._submitTimer
        itemView.inlineEdit.$().submit()
      , 0
    
  confirmRename: (itemView) ->
    if itemView.inlineEdit
      itemView.unsetClass "being-inline-edited"
      itemView.inlineEdit.destroy()
      itemView.$('.title').html itemView.getData().name
      delete itemView.inlineEdit
    
  cancelRename:(itemView)->
    if itemView.inlineEdit
      if itemView.inlineEdit.getOptions().deleteOnCancel
        @getCommand().emit 'fs.remove.start', {fileData : itemView.getData(), itemView, path: @pathForItem itemView}
        itemView.$().hide()
        # @removeItem itemView
      else
        itemView.unsetClass "being-inline-edited"
        itemView.inlineEdit.destroy()
        itemView.$('.title').html itemView.getData().name
        delete itemView.inlineEdit
      
  cancelDelete:(itemView)->
    if itemView.deleteContainer
      itemView.deleteContainer.destroy()
      itemView.unsetClass "being-inline-edited being-deleted"
      itemView.$('.finder-item').show()
      delete itemView.deleteContainer
  
  refreshSubItemsOfItem:(parentItem,subDataItems)->    
    newItemsData = @convertFinderDataToKDTreeViewData
      options:
        mount:           @mount
      newItemsData:      subDataItems
    super parentItem,newItemsData, no
    @propagateEvent KDEventType : 'FinderRefreshedItems'
    # @searchItemsToOpen()
    # @restoreSelected()

  # searchItemsToOpen: ->
  #   folders = @storage.get 'expandedFolders', []
  #   for item in @itemsOrdered
  #     # item.checkTitleSize()
  #     if item.getData().path in folders
  #       if not (item.expanded? and item.expanded)
  #         @_expandOrCollapseFolder item

  leftClick:(publishingInstance,event)->
  rightClick:(publishingInstance,event)->
  openFile:(publishingInstance,event)->
    data = publishingInstance.getData()
    @appendRecentFileList data
     
    appManager.openFile data
    # if publishingInstance instanceof FinderItemView
    #   @getCommand().emit 'fs.fetchFile.start', {path : (@pathForItem publishingInstance), fileData: publishingInstance.getData(), fileView: publishingInstance}
    # else #we got file instead of view, for case when finder still dont have that file rendered to tree
    #   {file} = publishingInstance
    #   item = @itemWithPath file.path
    #   @getCommand().emit 'fs.fetchFile.start', {path : file.path, fileData: file, fileView: item}
  
  openFileWithCodeMirror:(publishingInstance, event)->
    data = publishingInstance.getData()
    @appendRecentFileList data
     
    appManager.openFileWithApplication data, "CodeMirror.kdapplication"
  
  previewFile:(publishingInstance, event)->
    data = publishingInstance.getData()
    @appendRecentFileList data
      
    publicPath = data.path.replace /.*\/(.*\.beta.koding.com)\/httpdocs\/(.*)/, 'http://$1/$2'
    return if publicPath is data.path
    appManager.openFileWithApplication publicPath, "Viewer.kdapplication"
  
  appendRecentFileList:(data, callback)->
    # log data, "::::"
    @getStorage (storage)=>
      recentFiles = storage.getAt('bucket.recentFiles') or []
      unless data.path in recentFiles
        recentFiles.pop() if recentFiles.length is @getOptions().maxRecentFiles
        recentFiles.unshift data.path
      else
        recentFiles.sort (path)-> if path is data.path then -1 else 0
      storage.update {
        $set: 'bucket.recentFiles': recentFiles
      }, callback
    # newStorage = if localStorage.finderRecentFiles then (localStorage.finderRecentFiles).split ',' else []
    # if (newStorage.indexOf data.path) > -1
    #   newStorage.splice (newStorage.indexOf data.path), 1
    # newStorage.unshift data.path
    # newStorage.length = 10 if newStorage.length > 10
    # newStorage = newStorage.join '?-?'
    # localStorage.setItem 'finderRecentFiles', newStorage
  
  collapseFolder:(item)-> log "collapse folder"
  expandSection:(publishingInstance)-> log "expand section"

  checkPermissions:(options)->
    # switch options.operation
    #   # when "move" then yes if #mount of # options.source is #mount of # options.target
    #   else yes
    yes

  createContextMenu:(publishingItem, event)->
    @makeItemSelected publishingItem
    unless event.pageX and event.pageY
      bounds = publishingItem.getBounds()
      event.pageX = bounds.x + bounds.w - 20
      event.pageY = bounds.y + bounds.h/2
    contextMenu = new FinderContextMenu
      event    : event
      delegate : publishingItem.getDelegate()
    items = publishingItem.classContextMenu()
    contextMenu.addSubView menuTree = new KDContextMenuTreeView delegate : publishingItem
    new FinderContextMenuTreeViewController view : menuTree, {items}
    contextMenu.propagateEvent KDEventType : 'ContextMenuWantsToBeDisplayed', globalEvent : yes, event

  refresh: (item) ->
    @refreshFolder item

  expandFolder:(item)->
    if not item.expanded
      @expandOrCollapseFolder item

  rename:(itemView, options = {})->
    {deleteOnCancel, buttonTitle} = options
    
    input         = new FinderEditInputView finder: @getView()

    itemView.inlineEdit = form = new KDFormView
      deleteOnCancel: deleteOnCancel
      cssClass: "clearfix"
      callback: (formData,event)=>
        event.preventDefault()
        if @getCommand().isValidFileName(input.inputGetValue())
          itemData = itemView.getData()
          itemData.renameTo input.inputGetValue()
          @confirmRename itemView
          # @getCommand().emit 'fs.rename.start', {fileData: itemData, fileView: itemView, path:(@pathForItem itemView), newName: input.inputGetValue()}
          itemView.unsetClass "being-inline-edited"
          @makeItemSelected itemView,null
        else
          new KDNotificationView
            title: 'Wrong file name'
            duration: 1000
            
        no

    button        = new KDButtonView
      title : buttonTitle or 'Rename'
    button.hide()
        
    input.inputSetValue itemView.getData().name
    form.addSubView input
    form.addSubView button
    
    currentTitle  = '.title'
    itemView.$(currentTitle).html ''
    itemView.addSubView form, currentTitle
    
    @makeItemSelected itemView
    setTimeout ->
      input.inputSetFocus()
    , 0
    
  setPermissions: (itemView, {permissions, recursive}) ->
    @getCommand().emit 'fs.chmod.start', {permissions, recursive, fileData: itemView.getData(), path: @pathForItem itemView}
  
  fetchPermissions:(itemView, callback)->
    @getCommand().emit 'fs.stat.start', {callback, fileData:itemView.getData(), path:@pathForItem itemView}

  _remove: (itemView) ->
    itemView.unsetClass "being-inline-edited being-deleted"
    itemData = itemView.getData()
    
    itemData.remove ({error}) =>
      unless error
        @getStorage (storage) ->
          if storage
            storage.dropOption itemData.path
      
    @getView().mouseDown() # returning back key view
    
  remove:(itemView)->
    itemView.deleteContainer = container = new KDView cssClass : "delete-container"

    itemIndex     = @itemsOrdered.indexOf @
    selectItem  = if @itemsOrdered[itemIndex-1]
      @itemsOrdered[itemIndex-1]
    else if @itemsOrdered[itemIndex+1]
      @itemsOrdered[itemIndex+1]
    else
      no

    deleteButton  = new KDButtonView
      title : 'Delete'
      style: 'clean-red'
      callback: =>
        @_remove itemView
        # itemView.unsetClass "being-inline-edited being-deleted"
        # itemData = itemView.getData()
        # @getCommand().emit 'fs.remove.start', {fileData: itemData, path:@pathForItem itemView}
        # 
        # @removeItem itemView

    cancel = new FinderRemoveContainer finder:@, tagName : "a", partial : "CANCEL", cssClass : "cancel fr"
    
    @listenTo 
      KDEventTypes : "click"
      listenedToInstance : cancel
      callback : ()=>
        @cancelDelete itemView
    
    container.addSubView (label = new KDLabelView title : 'Are you sure?')
    container.addSubView cancel
    container.addSubView deleteButton
    itemView.addSubView container
    deleteButton.$().trigger "focus"
          
  gitHubClone: (item, params) ->
    form      = new KDFormView callback: (params) =>
      file = item.getData()
      file.cloneGitHub params, (err) ->
        log 'finished clone'
    urlInput  = new KDInputView name: 'gitUrl'
    label     = new KDLabelView title: 'GitHub url'
    
    form.addSubView label
    form.addSubView urlInput
    
    modal = new KDModalView
      title: 'GitHub clone'
      buttons:
        Clone: callback: =>
          form.submit()
          modal.destroy()
        Close: callback: =>
          modal.destroy()
          
    modal.addSubView form, '.kdmodal-content'
    
  # showHideHidden:->
  #   @propagateEvent { KDEventType: 'ShowOrHideHiddenFinderFiles', globalEvent : yes}
    
  createFolder:(itemView)->
    folder = itemView.getData()
    if folder.isFile()
      folder = folder.getParent()
      
    folder.createFolder ({error}) =>
      if error
        new FsErrorNotificationView
          title: 'Unable to create new folder'
          description: error

  createFile:(itemView)->
    folder = itemView.getData()
    if folder.isFile()
      folder = folder.getParent()
    
    folder.createFile ({error}) =>
      if error
        new FsErrorNotificationView
          title: 'Unable to create new file'
          description: error
      # @expandFolder folder

    # path = (@pathForItem itemView) + '/NewFile.txt'
    # @getCommand().emit 'fs.safePath.start', {filePath: path, parentItemView : itemView, type: 'file'}

  proceedCreation:(itemView)->
    itemView.performRename()
    @rename itemView, deleteOnCancel: yes, buttonTitle: 'Save'
      

  duplicateFile:(item)->
    @getCommand().once 'fs.duplicate.finish', (err, fileInfo)=>
      {fileData} = fileInfo
      fileData.getParent().list()
    @getCommand().emit 'fs.duplicate.start', {fileData: item.getData(), path: (@pathForItem item), view: item}
    
  download:(item)->
    items = @selectedItems
    datas = []
    for item in items
      datas.push item.getData()

    @fs.makePublic datas
    

  copyTo:(item, options)->
    {destination, items} = options
    for item in items
      item.copyTo destination, (a, b, c) ->
    # @getCommand().emit 'fs.copy.start', {copyTo: destination, items}

  moveTo:(item, options)->
    {destination, items} = options
    # @getCommand().emit 'fs.move.start', {moveTo: destination, items}
    for item in items
      item.moveTo destination, (a, b, c) ->

  compress:()->
    items = @selectedItems
    datas = []
    for item in items
      datas.push item.getData()

    @fs.compress datas 
    
  extract: (item) ->
    item.getData().extract()
  
  showKeyboardHelper:->
    finderItems = [
      { keySet : "up,down",               title : "Navigate files" }
      { keySet : "shift+up,down",         title : "Multiple selection" }
      { keySet : "left,right",            title : "Open/Close folders" }
      { keySet : "enter",                 title : "Open file" }
      { keySet : "delete",                title : "Delete file" }
      { keySet : "option+down",           title : "Context menu" }
    ]
    @_keyHelperModal.destroy() if @_keyHelperModal
    @_keyHelperModal = new KeyboardHelperModalView
      height    : "auto"
      position  :
        top     : 56
        right   : 5

    keyHelperController = new KDListViewController
      view    : new KeyboardHelperView
        title : "Finder Shortcuts"
    ,
      items   : finderItems

    @_keyHelperModal.addSubView keyHelperController.getView()

