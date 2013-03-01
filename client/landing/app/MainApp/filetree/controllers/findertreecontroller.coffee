class NFinderTreeController extends JTreeViewController

  constructor:->

    super

    if @getOptions().contextMenu
      @contextMenuController = new NFinderContextMenuController

      @contextMenuController.on "ContextMenuItemClicked", ({fileView, contextMenuItem})=>
        @contextMenuItemSelected fileView, contextMenuItem
    else
      @getView().setClass "no-context-menu"

    @getSingleton('mainController').on "NewFileIsCreated", (newFile)=> @navigateToNewFile newFile
    @getSingleton('mainController').on "SelectedFileChanged", (view)=> @highlightFile view

  addNode:(nodeData, index)->

    o = @getOptions()
    return if o.foldersOnly and nodeData.type is "file"
    # @setFileListeners nodeData if o.fsListeners
    item = super nodeData, index

  setItemListeners:(view, index)->

    super

    @setFileListeners view.getData()
    #
    # view.on "folderNeedsToRefresh", (newFile)=>
    #
    #   @navigateTo newFile.parentPath, =>
    #     @selectNode @nodes[newFile.path]
    #     @openFile @nodes[newFile.path]

  listenedPaths: {}

  setFileListeners:(file)->

    unless @listenedPaths[file.path]
      file.on "folderNeedsToRefresh", (newFile)=>
        @navigateTo newFile.parentPath, =>
          @selectNode @nodes[newFile.path]
        @listenedPaths[file.path] = file.path

  highlightFile:(view)->

    @selectNode @nodes[view.data.path], null, no

    if view.ace?
      if view.ace.editor?
        view.ace.editor.focus()
      else
        view.ace.on "ace.ready", ->
          view.ace.editor.focus()

  navigateToNewFile:(newFile)=>

    @navigateTo newFile.parentPath, =>

      # arr = []
      # unless @nodes[newFile.path]
      #   arr.push item.getData().path for item in @listControllers[newFile.parentPath].itemsOrdered
      #   arr.push newFile.path
      #   arr.sort()
      #   index = arr.indexOf newFile.path
      #   @addNode newFile, index

      @selectNode @nodes[newFile.path]

    # #
    # # file.on "fs.saveAs.finished", (newFile, oldFile)=>
    #
    #   log "fs.saveAs.finished", "+>>>>>"
    #
    #   parentNode = @nodes[path]
    #   if parentNode
    #     if parentNode.expanded
    #       @refreshFolder @nodes[path], =>
    #         @selectNode @nodes[path]
    #     else
    #       @expandFolder @nodes[parentPath], =>
    #         @selectNode @nodes[path]

    # file.on "fs.remotefile.created", (oldPath)=>
    #   tc = @treeController
    #   parentNode = tc.nodes[file.parentPath]
    #
    #   if parentNode
    #     if parentNode.expanded
    #       tc.refreshFolder tc.nodes[file.parentPath], ->
    #         tc.selectNode tc.nodes[file.path]
    #     else
    #       tc.expandFolder tc.nodes[file.parentPath], ->
    #         tc.selectNode tc.nodes[file.path]
    #   log "removed", oldPath
    #   delete @aceViews[oldPath]
    #   log "put", file.path
    #   @aceViews[file.path]

  getOpenFolders: ->

    return Object.keys(@listControllers).slice(1)


  ###
  FINDER OPERATIONS
  ###

  openItem:(nodeView, callback)->

    options  = @getOptions()
    nodeData = nodeView.getData()

    switch nodeData.type
      when "folder", "mount"
        @toggleFolder nodeView, callback
      when "file"
        @openFile nodeView
        @emit "file.opened", nodeData
        @setBlurState()

  openFile:(nodeView, event)->

    return unless nodeView
    file = nodeView.getData()
    KD.getSingleton("appManager").openFile file

  previewFile:(nodeView, event)->

    file = nodeView.getData()
    publicPath = file.path.replace /.*\/(.*\.koding.com)\/website\/(.*)/, 'http://$1/$2'
    if publicPath is file.path
      {nickname} = KD.whoami().profile
      KD.getSingleton("appManager").notify "File must be under: /#{nickname}/Sites/#{nickname}.#{location.hostname}/website/"
    else
      KD.getSingleton("appManager").openFileWithApplication publicPath, "Viewer"

  refreshFolder:(nodeView, callback)->

    @notify "Refreshing..."
    folder = nodeView.getData()
    folder.emit "fs.nothing.finished", [] # in case of refresh to stop the spinner

    @collapseFolder nodeView, =>
      @expandFolder nodeView, =>
        notification.destroy()
        callback?()

  toggleFolder:(nodeView, callback)->

    if nodeView.expanded then @collapseFolder nodeView, callback else @expandFolder nodeView, callback

  expandFolder:(nodeView, callback)->

    return unless nodeView
    return if nodeView.isLoading

    if nodeView.expanded
      callback? nodeView
      return

    cb = @utils.getCancellableCallback (files)=>
      @utils.killWait folder.failTimer
      nodeView.expand()
      @addNodes files
      callback? nodeView
      @emit "folder.expanded", nodeView.getData()
      @emit 'fs.retry.success'
      @hideNotification()

    folder = nodeView.getData()

    folder.failTimer = @utils.wait 5000, =>
      @notify "Couldn't fetch files! Click to retry", 'clickable', "Sorry, a problem occured while communicating with servers, please try again later.", yes
      @once 'fs.retry.scheduled', => @expandFolder nodeView, callback
      folder.emit "fs.nothing.finished", []
      cb.cancel()

    folder.fetchContents cb

  collapseFolder:(nodeView, callback)->

    return unless nodeView
    nodeData = nodeView.getData()
    {path} = nodeData

    @emit "folder.collapsed", nodeData

    if @listControllers[path]
      @listControllers[path].getView().collapse =>
        @removeChildNodes path
        nodeView.collapse()
        callback? nodeView
    else
      nodeView.collapse()
      callback? nodeView

  navigateTo:(path, callback)->

    return unless path

    path = path.split('/')
    path.shift()  if path[0] is ''
    path.pop()    if path[path.length-1] is ''
    path[1] = "/#{path[0]}/#{path[1]}"
    path.shift()

    index     = 0
    lastPath  = ''

    _expand = (path)=>
      nextPath = path.slice(0, ++index).join('/')
      if lastPath is nextPath
        @refreshFolder @nodes[nextPath], =>
          callback?()
        return

      @expandFolder @nodes[nextPath], =>
        lastPath = nextPath
        _expand path

    _expand path

  confirmDelete:(nodeView, event)->

    extension = nodeView.data?.getExtension() or null

    if @selectedNodes.length > 1
      new NFinderDeleteDialog {},
        items     : @selectedNodes
        callback  : (confirmation)=>
          @deleteFiles @selectedNodes if confirmation
          @setKeyView()
    else
      @beingEdited = nodeView
      nodeView.confirmDelete (confirmation)=>
        @deleteFiles [nodeView] if confirmation
        @setKeyView()
        @beingEdited = null

  deleteFiles:(nodes, callback)->

    stack = []
    nodes.forEach (node)=>
      stack.push (cb) =>
        node.getData().remove (err, response)=>
          if err then @notify null, null, err
          else
            cb err, node

    async.parallel stack, (error, result) =>
      @notify "#{result.length} item#{if result.length > 1 then 's' else ''} deleted!", "success"
      @removeNodeView node for node in result
      callback?()


  showRenameDialog:(nodeView)->

    @beingEdited = nodeView
    nodeData = nodeView.getData()
    oldPath = nodeData.path
    nodeView.showRenameView (newValue)=>
      return if newValue is nodeData.name
      nodeData.rename newValue, (err)=>
        if err then @notify null, null, err
        else
          delete @nodes[oldPath]
          @nodes[nodeView.getData().path] = nodeView
          nodeView.childView.render()

      # @setKeyView()
      @beingEdited = null

  createFile:(nodeView, type = "file")->

    @notify "creating a new #{type}!"
    nodeData = nodeView.getData()
    parentPath = if nodeData.type is "file"
      nodeData.parentPath
    else
      nodeData.path

    path = "#{parentPath}/New#{type.capitalize()}#{if type is 'file' then '.txt' else ''}"

    FSItem.create path, type, (err, file)=>
      if err
        @notify null, null, err
      else
        @refreshFolder @nodes[parentPath], =>
          @notify "#{type} created!", "success"
          node = @nodes[file.path]
          @selectNode node
          @showRenameDialog node


  moveFiles:(nodesToBeMoved, targetNodeView, callback)->

    targetItem = targetNodeView.getData()
    if targetItem.type is "file"
      targetNodeView = @nodes[targetNodeView.getData().parentPath]
      targetItem = targetNodeView.getData()

    stack = []
    nodesToBeMoved.forEach (node)=>
      stack.push (cb) =>
        sourceItem = node.getData()
        FSItem.move sourceItem, targetItem, (err, response)=>
          if err then @notify null, null, err
          else
            cb err, node

    callback or= (error, result) =>
      @notify "#{result.length} item#{if result.length > 1 then 's' else ''} moved!", "success"
      @removeNodeView node for node in result
      @refreshFolder targetNodeView

    async.parallel stack, callback

  copyFiles:(nodesToBeCopied, targetNodeView, callback)->

    targetItem = targetNodeView.getData()
    if targetItem.type is "file"
      targetNodeView = @nodes[targetNodeView.getData().parentPath]
      targetItem = targetNodeView.getData()

    stack = []
    nodesToBeCopied.forEach (node)=>
      stack.push (cb) =>
        sourceItem = node.getData()
        FSItem.copy sourceItem, targetItem, (err, response)=>
          if err then @notify null, null, err
          else
            cb err, node

    callback or= (error, result) =>
      @notify "#{result.length} item#{if result.length > 1 then 's' else ''} copied!", "success"
      @refreshFolder targetNodeView

    async.parallel stack, callback

  duplicateFiles:(nodes, callback)->

    stack = []
    nodes.forEach (node)=>
      stack.push (cb) =>
        sourceItem = node.getData()
        targetItem = @nodes[sourceItem.parentPath].getData()
        FSItem.copy sourceItem, targetItem, (err, response)=>
          if err then @notify null, null, err
          else
            cb err, node

    callback or= (error, result) =>
      @notify "#{result.length} item#{if result.length > 1 then 's' else ''} duplicated!", "success"
      parentNodes = []
      result.forEach (node)=>
        parentNode = @nodes[node.getData().parentPath]
        parentNodes.push parentNode unless parentNode in parentNodes
      @refreshFolder parentNode for parentNode in parentNodes

    async.parallel stack, callback

  compressFiles:(nodeView, type)->

    file = nodeView.getData()
    FSItem.compress file, type, (err, response)=>
      if err then @notify null, null, err
      else
        @notify "#{file.type.capitalize()} compressed!", "success"
        @refreshFolder @nodes[file.parentPath]

  extractFiles:(nodeView)->

    file = nodeView.getData()
    FSItem.extract file, (err, response)=>
      if err then @notify null, null, err
      else
        @notify "#{file.type.capitalize()} extracted!", "success"
        @refreshFolder @nodes[file.parentPath], =>
          @selectNode @nodes[response.path]

  compileApp:(nodeView, callback)->

    folder = nodeView.getData()
    folder.emit "fs.compile.started"
    kodingAppsController = @getSingleton('kodingAppsController')

    manifest = KodingAppsController.getManifestFromPath folder.path

    kodingAppsController.compileApp manifest.name, (err)=>
      folder.emit "fs.compile.finished"
      if not err
        @notify "App compiled!", "success"
        @utils.wait 500, =>
          @refreshFolder nodeView, =>
            @utils.wait =>
              @selectNode @nodes["#{folder.path}/index.js"]
      callback? err

  runApp:(nodeView, callback)->

    folder = nodeView.getData()
    folder.emit "fs.run.started"
    kodingAppsController = @getSingleton('kodingAppsController')

    manifest = KodingAppsController.getManifestFromPath folder.path

    kodingAppsController.runApp manifest, =>
      folder.emit "fs.run.finished"
      callback?()


  cloneRepo:(nodeView)->

    folder = nodeView.getData()

    @notify "not yet there!", "error"

    # folder.emit "fs.clone.started"
    # @getSingleton('kodingAppsController').cloneApp folder.path, =>
    #   folder.emit "fs.clone.finished"
    #   @refreshFolder @nodes[folder.parentPath], =>
    #     @utils.wait 500, =>
    #       @selectNode @nodes[folder.path]
    #       @refreshFolder @nodes[folder.path]
    #   @notify "App cloned!", "success"

  publishApp:(nodeView)->

    folder = nodeView.getData()

    folder.emit "fs.publish.started"
    @getSingleton('kodingAppsController').publishApp folder.path, (err)=>
      folder.emit "fs.publish.finished"
      unless err
        @notify "App published!", "success"
      else
        @notify "Publish failed!", "error", err
        if err.message
          modal = new KDModalView
            title        : "Publish failed!"
            overlay      : yes
            cssClass     : "new-kdmodal"
            content      : "<div class='modalformline'>#{err.message}</div>"
            buttons      :
              "Close"    :
                style    : "modal-clean-gray"
                callback : (event)->
                  modal.destroy()

  makeNewApp:(nodeView)->
    @getSingleton('kodingAppsController').makeNewApp()

  downloadAppSource:(nodeView)->

    folder = nodeView.getData()

    folder.emit "fs.sourceDownload.started"
    @getSingleton('kodingAppsController').downloadAppSource folder.path, (err)=>
      folder.emit "fs.sourceDownload.finished"
      @refreshFolder @nodes[folder.parentPath]
      unless err
        @notify "Source downloaded!", "success"
      else
        @notify "Download failed!", "error", err

  createCodeShare:({data})->

    CodeShares = []
    @notify "Fetching file list..."

    data.fetchContents (items)=>
      @notify "Fetching file contents..."
      files = (file for file in items when file.constructor.name is 'FSFile')
      count = 0
      # Poor mans queue mechanism
      for file in files
        do (file)->
          file.fetchContents (err, content)->
            count+=1
            if not err and content
              CodeShare =
                CodeShareItemOptions : {}
                CodeShareItemSource  : content
                CodeShareItemTitle   : file.name
                CodeShareItemType    :
                  syntax             : @utils.getFileExtension file.path
              CodeShares.push CodeShare
            if count == files.length
              @getSingleton('mainController').emit 'CreateNewActivityRequested', 'JCodeShare', CodeShares

  ###
  CONTEXT MENU OPERATIONS
  ###

  cmExpand:       (nodeView, contextMenuItem)-> @expandFolder node for node in @selectedNodes
  cmCollapse:     (nodeView, contextMenuItem)-> @collapseFolder node for node in @selectedNodes # error fix this
  cmRefresh:      (nodeView, contextMenuItem)-> @refreshFolder nodeView
  cmCreateFile:   (nodeView, contextMenuItem)-> @createFile nodeView
  cmCreateFolder: (nodeView, contextMenuItem)-> @createFile nodeView, "folder"
  cmRename:       (nodeView, contextMenuItem)-> @showRenameDialog nodeView
  cmDelete:       (nodeView, contextMenuItem)-> @confirmDelete nodeView
  cmDuplicate:    (nodeView, contextMenuItem)-> @duplicateFiles @selectedNodes
  cmExtract:      (nodeView, contextMenuItem)-> @extractFiles nodeView
  cmZip:          (nodeView, contextMenuItem)-> @compressFiles nodeView, "zip"
  cmTarball:      (nodeView, contextMenuItem)-> @compressFiles nodeView, "tar.gz"
  cmUpload:       (nodeView, contextMenuItem)-> KD.getSingleton("appManager").notify()
  cmDownload:     (nodeView, contextMenuItem)-> KD.getSingleton("appManager").notify()
  cmGitHubClone:  (nodeView, contextMenuItem)-> KD.getSingleton("appManager").notify()
  cmOpenFile:     (nodeView, contextMenuItem)-> @openFile nodeView
  cmPreviewFile:  (nodeView, contextMenuItem)-> @previewFile nodeView
  cmCompile:      (nodeView, contextMenuItem)-> @compileApp nodeView
  cmRunApp:       (nodeView, contextMenuItem)-> @runApp nodeView
  cmMakeNewApp:   (nodeView, contextMenuItem)-> @makeNewApp nodeView
  cmDownloadApp:  (nodeView, contextMenuItem)-> @downloadAppSource nodeView
  cmCloneRepo:    (nodeView, contextMenuItem)-> @cloneRepo nodeView
  cmPublish:      (nodeView, contextMenuItem)-> @publishApp nodeView
  cmCodeShare:    (nodeView, contextMenuItem)-> @createCodeShare nodeView

  cmOpenFileWithCodeMirror:(nodeView, contextMenuItem)-> KD.getSingleton("appManager").notify()

  ###
  CONTEXT MENU CREATE/MANAGE
  ###

  createContextMenu:(nodeView, event)->

    event.stopPropagation()
    event.preventDefault()
    return if nodeView.beingDeleted or nodeView.beingEdited

    if nodeView in @selectedNodes
      contextMenu = @contextMenuController.getContextMenu @selectedNodes, event
    else
      @selectNode nodeView
      contextMenu = @contextMenuController.getContextMenu [nodeView], event
    no

  contextMenuItemSelected:(nodeView, contextMenuItem)->

    {action} = contextMenuItem.getData()
    if action
      if @["cm#{action.capitalize()}"]?
        @contextMenuController.destroyContextMenu()
      @["cm#{action.capitalize()}"]? nodeView, contextMenuItem

  ###
  RESET STATES
  ###

  resetBeingEditedItems:->

    @beingEdited.resetView()

  organizeSelectedNodes:(listController, nodes, event = {})->

    @resetBeingEditedItems() if @beingEdited
    super

  ###
  DND UI FEEDBACKS
  ###

  showDragOverFeedback:(nodeView, event)-> super

  clearDragOverFeedback:(nodeView, event)-> super

  clearAllDragFeedback:-> super

  ###
  HANDLING MOUSE EVENTS
  ###

  click:(nodeView, event)->

    if $(event.target).is ".chevron"
      @contextMenu nodeView, event
      return no
    super

  dblClick:(nodeView, event)->

    @openItem nodeView

  contextMenu:(nodeView, event)->

    if @getOptions().contextMenu
      @createContextMenu nodeView, event

  ###
  HANDLING DND
  ###

  dragOver: (nodeView, event)->

    @showDragOverFeedback nodeView, event
    super

  lastEnteredNode = null
  dragEnter: (nodeView, event)->

    return nodeView if lastEnteredNode is nodeView or nodeView in @selectedNodes
    lastEnteredNode = nodeView
    clearTimeout @expandTimeout
    if nodeView.getData().type is ("folder" or "mount")
      @expandTimeout = setTimeout (=> @expandFolder nodeView), 800
    @showDragOverFeedback nodeView, event
    e = event.originalEvent

    if @boundaries.top > e.pageY > @boundaries.top + 20
      log "trigger top scroll"

    if @boundaries.top + @boundaries.height < e.pageY < @boundaries.top + @boundaries.height + 20
      log "trigger down scroll"

    super


  dragLeave: (nodeView, event)->

    @clearDragOverFeedback nodeView, event
    super

  dragEnd: (nodeView, event)->

    # log "clear after drag"
    @clearAllDragFeedback()
    super

  drop: (nodeView, event)->

    return if nodeView in @selectedNodes

    sameParent = no
    @selectedNodes.forEach (selectedNode)->
      sameParent = yes if selectedNode.getData().parentPath is nodeView.getData().parentPath

    return if sameParent

    if event.altKey
      @copyFiles @selectedNodes, nodeView
    else
      @moveFiles @selectedNodes, nodeView

    super

  ###
  HANDLING KEY EVENTS
  ###

  keyEventHappened:(event)->

    super

  performDownKey:(nodeView, event)->

    if event.altKey
      offset = nodeView.$('.chevron').offset()
      event.pageY = offset.top
      event.pageX = offset.left
      @contextMenu nodeView, event
    else
      super

  performBackspaceKey:(nodeView, event)->

    event.preventDefault()
    event.stopPropagation()
    @confirmDelete nodeView, event
    no

  performEnterKey:(nodeView, event)->

    @selectNode nodeView
    @openItem nodeView

  performRightKey:(nodeView, event)->

    {type} = nodeView.getData()
    if /mount|folder/.test type
      @expandFolder nodeView

  performUpKey:(nodeView, event)-> super
  performLeftKey:(nodeView, event)->

    if nodeView.expanded
      @collapseFolder nodeView
      return no
    super


  ###
  HELPERS
  ###

  notification  = null
  autoTriedOnce = no

  hideNotification: ->
    notification.destroy() if notification

  notify:(msg, style, details, reconnect=no)->

    return unless @getView().parent?

    notification.destroy() if notification

    if details and not msg? and /Permission denied/.test details
      msg = "Permission denied!"

    style or= 'error' if details
    duration = if reconnect then 0 else if details then 5000 else 2500

    if not autoTriedOnce and reconnect
      KD.utils.wait 200, =>
        @emit 'fs.retry.scheduled'
        @getSingleton('kiteController')?.channels?.sharedHosting?.cycleChannel?()
      autoTriedOnce = yes
      return

    notification = new KDNotificationView
      title     : msg or "Something went wrong"
      type      : "mini"
      cssClass  : "filetree #{style}"
      container : @getView().parent
      # duration  : 0
      duration  : duration
      details   : details
      click     : =>
        if reconnect
          @emit 'fs.retry.scheduled'
          @getSingleton('kiteController')?.channels?.sharedHosting?.cycleChannel?()
          notification.notificationSetTitle 'Attempting to fetch files'
          notification.notificationSetPositions()
          notification.setClass 'loading'

          @utils.wait 6000, notification.bound "destroy"
          @once 'fs.retry.success', notification.bound "destroy"
          return

        if notification.getOptions().details
          details = new KDNotificationView
            title     : "Error details"
            content   : notification.getOptions().details
            type      : "growl"
            duration  : 0
            click     : -> details.destroy()

          @getSingleton('windowController').addLayer details
          details.on 'ReceivedClickElsewhere', ->
            details.destroy()
