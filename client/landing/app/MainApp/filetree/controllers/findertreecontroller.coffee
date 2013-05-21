class NFinderTreeController extends JTreeViewController

  constructor:->

    super

    if @getOptions().contextMenu
      @contextMenuController = new NFinderContextMenuController

      @contextMenuController.on "ContextMenuItemClicked", ({fileView, contextMenuItem})=>
        @contextMenuItemSelected fileView, contextMenuItem
    else
      @getView().setClass "no-context-menu"

    @getSingleton('mainController').on "NewFileIsCreated", @bound "navigateToNewFile"
    @getSingleton('mainController').on "SelectedFileChanged", @bound "highlightFile"

  addNode:(nodeData, index)->

    o = @getOptions()
    return if o.foldersOnly and nodeData.type is "file"
    item = super nodeData, index

  highlightFile:(view)->

    @selectNode @nodes[view.data.path], null, no

    if view.ace?
      if view.ace.editor?
        view.ace.editor.focus()
      else
        view.ace.on "ace.ready", ->
          view.ace.editor.focus()

  navigateToNewFile:(newFile)->

    @navigateTo newFile.parentPath, =>
      @selectNode @nodes[newFile.path]

  getOpenFolders: ->

    return Object.keys(@listControllers).slice(1)

  ###
  FINDER OPERATIONS
  ###

  openItem:(nodeView, callback)->

    options  = @getOptions()
    nodeData = nodeView.getData()

    switch nodeData.type
      when "folder", "mount", "vm"
        @toggleFolder nodeView, callback
      when "file"
        @openFile nodeView
        @emit "file.opened", nodeData
        @setBlurState()

  openFile:(nodeView, contextMenuItem)->

    return unless nodeView
    file = nodeView.getData()
    app  = contextMenuItem?.getData().title or null
    @getSingleton("appManager").openFile file, app

  previewFile:(nodeView, event)->

    file       = nodeView.getData()
    appManager = KD.getSingleton("appManager")
    publicPath = file.path.replace /.*\/(.*\.koding.com)\/website\/(.*)/, 'http://$1/$2'

    if publicPath is file.path
      {nickname} = KD.whoami().profile
      appManager.notify "File must be under: /#{nickname}/Sites/#{nickname}.#{location.hostname}/website/"
    else
      appManager.openFile publicPath, "Viewer"

  resetVm:(nodeView)->
    KD.getSingleton('vmController').reinitialize()

  makeTopFolder:(nodeView)->
    KD.getSingleton('finderController').createRootStructure \
      nodeView.getData().path

  refreshFolder:(nodeView, callback)->

    @notify "Refreshing..."
    folder = nodeView.getData()
    folder.emit "fs.job.finished", [] # in case of refresh to stop the spinner

    @collapseFolder nodeView, =>
      @expandFolder nodeView, =>
        notification.destroy()
        callback?()

  toggleFolder:(nodeView, callback)->
    if nodeView.expanded
      @collapseFolder nodeView, callback
    else
      @expandFolder nodeView, callback

  expandFolder:(nodeView, callback)->

    return unless nodeView
    return if nodeView.isLoading

    if nodeView.expanded
      callback? nodeView
      return

    folder = nodeView.getData()

    failCallback = =>
      @notify "Couldn't fetch files! Click to retry", 'clickable', \
              """Sorry, a problem occured while communicating with servers,
                 please try again later.""", yes
      @once 'fs.retry.scheduled', => @expandFolder nodeView, callback
      folder.emit "fs.job.finished", []

    folder.fetchContents (KD.utils.getTimedOutCallback (err, files)=>
      unless err
        nodeView.expand()
        if files
          @addNodes files
        callback? nodeView
        @emit "folder.expanded", nodeView.getData()
        @emit 'fs.retry.success'
        @hideNotification()
      else
        failCallback()
    , failCallback), no

  collapseFolder:(nodeView, callback)->

    return unless nodeView
    folder = nodeView.getData()
    {path} = folder

    @emit "folder.collapsed", folder

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
      if @nodes["#{nodeData.parentPath}/#{newValue}"]
        caretPos = nodeView.renameView.input.getCaretPosition()
        @notify "#{nodeData.type.capitalize()} exist!", "error"
        return KD.utils.defer =>
          @showRenameDialog nodeView
          nodeView.renameView.input.setCaretPosition caretPos

      nodeData.rename newValue, (err)=>
        if err then @notify null, null, err
        # else
        #   delete @nodes[oldPath]
        #   @nodes[nodeView.getData().path] = nodeView
        #   nodeView.childView.render()

      # @setKeyView()
      @beingEdited = null

  createFile:(nodeView, type = "file")->

    @notify "creating a new #{type}!"
    nodeData = nodeView.getData()

    if nodeData.type is "file"
      {parentPath} = nodeData
    else
      parentPath = nodeData.path

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
    folder.emit "fs.job.started"
    kodingAppsController = @getSingleton('kodingAppsController')

    manifest = KodingAppsController.getManifestFromPath folder.path

    kodingAppsController.compileApp manifest.name, (err)=>
      folder.emit "fs.job.finished"
      if not err
        @notify "App compiled!", "success"
        @utils.wait 500, =>
          @refreshFolder nodeView, =>
            @utils.defer =>
              @selectNode @nodes["#{folder.path}/index.js"]
      callback? err

  runApp:(nodeView, callback)->

    folder = nodeView.getData()
    folder.emit "fs.job.started"
    kodingAppsController = @getSingleton('kodingAppsController')

    manifest = KodingAppsController.getManifestFromPath folder.path

    kodingAppsController.runApp manifest, =>
      folder.emit "fs.job.finished"
      callback?()


  cloneRepo:(nodeView)->

    folder = nodeView.getData()

    @notify "not yet there!", "error"

    # folder.emit "fs.job.started"
    # @getSingleton('kodingAppsController').cloneApp folder.path, =>
    #   folder.emit "fs.job.finished"
    #   @refreshFolder @nodes[folder.parentPath], =>
    #     @utils.wait 500, =>
    #       @selectNode @nodes[folder.path]
    #       @refreshFolder @nodes[folder.path]
    #   @notify "App cloned!", "success"

  publishApp:(nodeView)->

    folder = nodeView.getData()

    folder.emit "fs.job.started"
    @getSingleton('kodingAppsController').publishApp folder.path, (err)=>
      folder.emit "fs.job.finished"
      unless err
        @notify "App published!", "success"
      else
        @notify "Publish failed!", "error", err
        message = err.message or err
        modal = new KDModalView
          title        : "Publish failed!"
          overlay      : yes
          cssClass     : "new-kdmodal"
          content      : "<div class='modalformline'>#{message}</div>"
          buttons      :
            "Close"    :
              style    : "modal-clean-gray"
              callback : (event)->
                modal.destroy()

  makeNewApp:(nodeView)->
    @getSingleton('kodingAppsController').makeNewApp()

  downloadAppSource:(nodeView)->

    folder = nodeView.getData()

    folder.emit "fs.job.started"
    @getSingleton('kodingAppsController').downloadAppSource folder.path, (err)=>
      folder.emit "fs.job.finished"
      @refreshFolder @nodes[folder.parentPath]
      unless err
        @notify "Source downloaded!", "success"
      else
        @notify "Download failed!", "error", err

  createCodeShare:({data})->

    CodeShares = []
    @notify "Fetching file list..."

    data.fetchContents (err, items)=>
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
                  syntax             : FSItem.getFileExtension file.path
              CodeShares.push CodeShare
            if count == files.length
              @getSingleton('mainController').emit 'CreateNewActivityRequested', 'JCodeShare', CodeShares

  openTerminalFromHere: (nodeView) ->
    appManager.open "WebTerm", (appInstance) =>
      path          = nodeView.getData().path
      appManager    = @getSingleton "appManager"
      {webTermView} = appManager.getFrontApp().getView().tabView.getActivePane().getOptions()

      webTermView.on "WebTermConnected", (server) =>
        server.input "cd #{path}\n"

  ###
  CONTEXT MENU OPERATIONS
  ###

  cmExpand:       (nodeView, contextMenuItem)-> @expandFolder node for node in @selectedNodes
  cmCollapse:     (nodeView, contextMenuItem)-> @collapseFolder node for node in @selectedNodes # error fix this
  cmMakeTopFolder:(nodeView, contextMenuItem)-> @makeTopFolder nodeView
  cmRefresh:      (nodeView, contextMenuItem)-> @refreshFolder nodeView
  cmResetVm:      (nodeView, contextMenuItem)-> @resetVm nodeView
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
  cmOpenFile:     (nodeView, contextMenuItem)-> @openFile nodeView, contextMenuItem
  cmPreviewFile:  (nodeView, contextMenuItem)-> @previewFile nodeView
  cmCompile:      (nodeView, contextMenuItem)-> @compileApp nodeView
  cmRunApp:       (nodeView, contextMenuItem)-> @runApp nodeView
  cmMakeNewApp:   (nodeView, contextMenuItem)-> @makeNewApp nodeView
  cmDownloadApp:  (nodeView, contextMenuItem)-> @downloadAppSource nodeView
  cmCloneRepo:    (nodeView, contextMenuItem)-> @cloneRepo nodeView
  cmPublish:      (nodeView, contextMenuItem)-> @publishApp nodeView
  cmCodeShare:    (nodeView, contextMenuItem)-> @createCodeShare nodeView
  cmOpenTerminal: (nodeView, contextMenuItem)-> @openTerminalFromHere nodeView
  cmShowOpenWithModal: (nodeView, contextMenuItem)-> @showOpenWithModal nodeView

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

    if $(event.target).is ".arrow"
      @openItem nodeView
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
    return unless nodeView.getData?().type in ['folder', 'mount']

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
    if /mount|folder|vm/.test type
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
  autoTriedOnce = yes

  hideNotification: ->
    notification.destroy() if notification

  notify:(msg, style, details, reconnect=no)->

    return unless @getView().parent?

    notification.destroy() if notification

    if details and not msg? and /Permission denied/.test details?.message
      msg = "Permission denied!"

    style or= 'error' if details
    duration = if reconnect then 0 else if details then 5000 else 2500

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

  refreshTopNode:->
    KD.logToMixpanel "sharedHosting click on refresh success"

    {nickname} = KD.whoami().profile
    @refreshFolder @nodes["/Users/#{nickname}"], => @emit "fs.retry.success"

  showOpenWithModal: (nodeView) ->
    appManager     = @getSingleton "appManager"
    appsController = @getSingleton "kodingAppsController"
    fileName       = FSHelper.getFileNameFromPath nodeView.getData().path
    fileExtension  = FSItem.getFileExtension fileName

    appsController.fetchApps (err, apps) =>
      modal = new KDModalView
        title         : "Choose application to open #{fileName}"
        cssClass      : "open-with-modal"
        overlay       : yes
        width         : 400
        buttons       :
          Open        :
            title     : "Open"
            style     : "modal-clean-green"
            callback  : =>
              appName = modal.selectedApp.getData().name

              if @alwaysOpenWith.getValue()
                appsController.emit "UpdateDefaultApp", fileExtension, appName

              appManager.openFile nodeView.getData(), appName
              modal.destroy()
          Cancel     :
            title    : "Cancel"
            style    : "modal-cancel"
            callback : => modal.destroy()

      {extensionToApp} = appsController
      supportedApps    = extensionToApp[fileExtension] or extensionToApp.txt

      for appName in supportedApps
        modal.addSubView new OpenWithModalApp
          supported : yes
          delegate  : modal
        , apps[appName]

      modal.addSubView new KDView
        cssClass     : "separator"

      for appName, manifest of apps when supportedApps.indexOf(appName) is -1
        modal.addSubView new OpenWithModalApp { delegate: modal }, manifest

      label = new KDLabelView
        title        : "Always open with..."
        attributes   :
          "for"      : "alwaysOpenWith"

      @alwaysOpenWith = new KDInputView
        type         : "checkbox"
        domId        : "alwaysOpenWith"

      modal.buttonHolder.addSubView @alwaysOpenWith
      modal.buttonHolder.addSubView label

class OpenWithModalApp extends JView

  constructor: (options= {}, data) ->

    options.cssClass = "app"

    super options, data

    {authorNick, name, version, icns} = manifest = @getData()

    resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

    if manifest.devMode
      resourceRoot = "https://#{authorNick}.koding.com/.applications/#{__utils.slugify name}/"

    thumb  = "#{KD.apiUri + '/images/default.app.thumb.png'}"

    for size in [64, 128, 160, 256, 512]
      if icns and icns[String size]
        thumb = "#{resourceRoot}/#{icns[String size]}"
        break

    @img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @img.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    @setClass "not-supported" unless @getOptions().supported

    @on "click", =>
      delegate = @getDelegate()
      delegate.selectedApp.unsetClass "selected" if delegate.selectedApp
      @setClass "selected"
      delegate.selectedApp = @

  pistachio: ->
    data = @getData()

    return """
      {{> @img}}
      <div class="app-name">#{data.name}</div>
    """