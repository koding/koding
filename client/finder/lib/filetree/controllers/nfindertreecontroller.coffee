Promise                   = require 'bluebird'
$                         = require 'jquery'
kd                        = require 'kd'
JTreeViewController       = kd.JTreeViewController
KDCustomHTMLView          = kd.CustomHTMLView
KDModalView               = kd.ModalView
KDNotificationView        = kd.NotificationView
globals                   = require 'globals'
whoami                    = require 'app/util/whoami'
KodingAppsController      = require 'app/kodingappscontroller'
FSHelper                  = require 'app/util/fs/fshelper'
getPublicURLOfPath        = require 'app/util/getPublicURLOfPath'
CloneRepoModal            = require 'app/commonviews/clonerepomodal'
NFinderDeleteDialog       = require '../itemsubviews/nfinderdeletedialog'
Encoder                   = require 'htmlencode'
Tracker                   = require 'app/util/tracker'


module.exports = class NFinderTreeController extends JTreeViewController

  constructor: (options, data) ->

    options.view or= new KDCustomHTMLView { cssClass : 'jtreeview-wrapper' }

    super options, data

    if @getOptions().contextMenu
      { contextMenuClass } = @getOptions()

      @contextMenuController = new contextMenuClass

      @contextMenuController.on 'ContextMenuItemClicked', ({ fileView, contextMenuItem }) =>
        @contextMenuItemSelected fileView, contextMenuItem
    else
      @getView().setClass 'no-context-menu'

    @appManager    = kd.getSingleton 'appManager'
    mainController = kd.getSingleton 'mainController'

    mainController.on 'NewFileIsCreated', @bound 'navigateToNewFile'
    mainController.on 'SelectedFileChanged', @bound 'highlightFile'

  addNode: (nodeData, index) ->
    fc = @getDelegate()
    return if @getOption('foldersOnly') and nodeData.type is 'file'
    return if nodeData.isHidden() and fc.isNodesHiddenFor nodeData.machine.uid
    item = super nodeData, index


  highlightFile: (view) ->

    return  if @isReadOnly

    @selectNode @nodes[view.data.path], null, no

    { ace } = view

    return  unless ace

    { editor } = ace

    if editor
    then editor.focus()
    else ace.ready -> editor.focus()


  navigateToNewFile: (newFile) ->

    @navigateTo newFile.parentPath, =>
      @selectNode @nodes[newFile.path]

  getOpenFolders: ->

    return Object.keys(@listControllers).slice(1)

  ###
  FINDER OPERATIONS
  ###

  openItem: (nodeView, callback) ->

    return  if @isReadOnly

    options  = @getOptions()
    nodeData = nodeView.getData()

    switch nodeData.type
      when 'folder', 'mount', 'vm', 'machine'
        @toggleFolder nodeView, callback
      when 'file'
        @openFile nodeView
        @emit 'file.opened', nodeData
        @setBlurState()

  openFileWithApp: (nodeView, contextMenuItem) ->
    return kd.warn 'no app passed to open this file'  unless contextMenuItem
    app = contextMenuItem.getData().title
    kd.getSingleton('appManager').openFileWithApplication app, nodeView.getData()

  openFile: (nodeView) ->

    return  if @isReadOnly
    return unless nodeView

    file = nodeView.getData()
    # @appManager.openFile file
    @getDelegate().emit 'FileNeedsToBeOpened', file

  tailFile: (nodeView) ->

    return  unless nodeView
    return  if @isReadOnly

    Tracker.track Tracker.FILETREE_WATCH_FILE

    @getDelegate().emit 'FileNeedsToBeTailed', { file: nodeView.getData() }

  previewFile: (nodeView) ->
    { vmName, path } = nodeView.getData()
    @appManager.open 'Viewer', { params: { path, vmName } }


  unmountVm: (nodeView) ->
    { machine: { uid } } = nodeView.getData()
    @getDelegate().unmountMachine uid

  openMachineTerminal: (nodeView) ->
    { machine } = nodeView.getData()
    appManager  = kd.getSingleton 'appManager'
    ideApp      = appManager.get 'IDE'
    callback    = -> appManager.tell 'IDE', 'openMachineTerminal', machine

    if ideApp then callback() else appManager.open 'IDE', callback

  toggleDotFiles: (nodeView) ->

    finder = @getDelegate()
    { machine: { uid } } = nodeView.getData()

    if finder.isNodesHiddenFor uid
    then finder.showDotFiles uid
    else finder.hideDotFiles uid

  makeTopFolder: (nodeView) ->
    { machine, path } = nodeView.getData()
    finder = @getDelegate()
    finder.updateMachineRoot machine.uid, FSHelper.plainPath path

  refreshFolder: (nodeView, callback) ->

    @notify 'Refreshing...'
    folder = nodeView.getData()
    folder.emit 'fs.job.finished', [] # in case of refresh to stop the spinner

    Tracker.track Tracker.FILETREE_REFRESH

    @collapseFolder nodeView, =>
      kd.utils.defer => @expandFolder nodeView, ->
        notification.destroy()
        callback?()

  toggleFolder: (nodeView, callback) ->
    if nodeView.expanded
      @collapseFolder nodeView, callback
    else
      @expandFolder nodeView, callback

  expandFolder: (nodeView, callback, silence = no) ->

    return unless nodeView
    return if nodeView.isLoading

    if nodeView.expanded
      callback? null, nodeView
      return

    folder = nodeView.getData()

    if folder.depth > 10
      @notify 'Folder is nested deeply, making it top folder'
      @makeTopFolder nodeView

    failCallback = (err) =>
      unless silence
        if err?.message?.match /permission denied/i
          message = 'Permission denied!'
        else
          message = "Couldn't fetch files! Click to retry"
        @notify message, null, \
                '''Sorry, a problem occurred while communicating with servers,
                   please try again later.''', yes
        @once 'fs.retry.scheduled', => @expandFolder nodeView, callback
      folder.emit 'fs.job.finished', []
      callback? err

    folder.fetchContents no, (kd.utils.getTimedOutCallback (err, files) =>
      unless err
        nodeView.expand()
        if files
          @addNodes files
        callback? null, nodeView
        @emit 'folder.expanded', nodeView.getData()  unless silence
        @emit 'fs.retry.success'
        @hideNotification()
      else
        failCallback err
    , failCallback, globals.config.fileFetchTimeout)

  collapseFolder: (nodeView, callback, silence = no) ->

    return unless nodeView
    folder   = nodeView.getData()
    { path } = folder

    @emit 'folder.collapsed', folder  unless silence

    if @listControllers[path]
      @listControllers[path].getView().collapse =>
        @removeChildNodes path
        nodeView.collapse()
        callback? nodeView
    else
      nodeView.collapse()
      callback? nodeView

  navigateTo: (path, callback) ->

    return unless path

    path = path.split('/')
    path.shift()  if path[0] is ''
    path.pop()    if path[path.length - 1] is ''
    path[1] = "/#{path[0]}/#{path[1]}"
    path.shift()

    index     = 0
    lastPath  = ''

    _expand = (path) =>
      nextPath = path.slice(0, ++index).join('/')
      if lastPath is nextPath
        @refreshFolder @nodes[nextPath], ->
          callback?()
        return

      @expandFolder @nodes[nextPath], ->
        lastPath = nextPath
        _expand path

    _expand path

  confirmDelete: (nodeView, event) ->

    extension = nodeView.data?.getExtension() or null

    if @selectedNodes.length > 1
      new NFinderDeleteDialog {},
        items     : @selectedNodes
        callback  : (confirmation) =>
          @deleteFiles @selectedNodes if confirmation
          @setKeyView()
    else
      @beingEdited = nodeView
      nodeView.confirmDelete (confirmation) =>
        @deleteFiles [nodeView] if confirmation
        @setKeyView()
        @beingEdited = null

  deleteFiles: (nodes, callback) ->

    deletedNodes = []
    results = nodes.map (node) ->
      node.getData().remove().then ->
        node.emit 'ItemBeingDeleted'
        deletedNodes.push node

    Promise.all(results).then =>
      Tracker.track Tracker.FILETREE_DELETE_FILE_FOLDER
      @notify "#{deletedNodes.length} item#{if deletedNodes.length > 1 then 's' else ''} deleted!", 'success'
      @emit 'NodesRemoved', deletedNodes
      @removeNodeView node for node in deletedNodes

    .catch (err) =>
      @notify null, null, err

    .nodeify callback

  showRenameDialog: (nodeView) ->

    return  unless nodeView

    @selectNode nodeView
    @beingEdited = nodeView
    nodeData = nodeView.getData()
    oldPath = nodeData.path
    nodeView.showRenameView (newValue) =>
      newValue = Encoder.XSSEncode newValue
      return  if newValue is nodeData.name
      return  unless FSHelper.isValidFileName newValue

      nodeData.rename newValue, (err) =>
        if err then @notify null, null, err

        nodeData.emit 'FilePathChanged', newValue
        Tracker.track Tracker.FILETREE_RENAME_FILE_FOLDER

      @beingEdited = null

  createFile: (nodeView, type = 'file') ->

    @notify "creating a new #{type}!"
    nodeData = nodeView.getData()

    { machine } = nodeData

    if nodeData.type is 'file'
      { parentPath } = nodeData
    else
      parentPath = nodeData.path

    path = FSHelper.plainPath \
      "#{parentPath}/New#{type.capitalize()}#{if type is 'file' then '.txt' else ''}"

    machine.fs.create { path, type, treeController: this }, (err, file) =>
      if err
        @notify null, null, err
      else
        kd.utils.defer =>
          @notify "#{type} created!", 'success'
          Tracker.track Tracker.FILETREE_NEW_FILE if type is 'file'
          Tracker.track Tracker.FILETREE_NEW_FOLDER if type is 'folder'
          node = @nodes[file.path]

          return @showRenameDialog node  if node

          @refreshFolder @nodes[parentPath], =>
            @showRenameDialog @nodes[file.path]


  moveFiles: (nodesToBeMoved, targetNodeView, callback) ->

    targetItem = targetNodeView.getData()
    if targetItem.type is 'file'
      targetNodeView = @nodes[targetNodeView.getData().parentPath]
      targetItem = targetNodeView.getData()

    movedNodes = []
    results = nodesToBeMoved.map (node) ->
      sourceItem = node.getData()
      sourceItem.move("#{targetItem.path}/").then ->
        movedNodes.push node

    Promise.all(results).then =>
      @emit 'NodesMoved', movedNodes, targetItem
      @notify "#{movedNodes.length} item#{if movedNodes.length > 1 then 's' else ''} moved!", 'success'
      @removeNodeView node for node in movedNodes
      @refreshFolder targetNodeView

    .catch (err) =>
      kd.warn 'Move failed with error:', err
      @notify null, null, err

    .nodeify callback

  copyFiles: (nodesToBeCopied, targetNodeView, callback) ->

    targetItem = targetNodeView.getData()
    if targetItem.type is 'file'
      targetNodeView = @nodes[targetNodeView.getData().parentPath]
      targetItem = targetNodeView.getData()

    copiedNodes = []
    results = nodesToBeCopied.map (node) ->
      sourceItem = node.getData()
      sourceItem.copy(targetItem.path).then ->
        copiedNodes.push node

    Promise.all(results).then =>
      @notify "#{copiedNodes.length} item#{if copiedNodes.length > 1 then 's' else ''} copied!", 'success'

    .catch (err) =>
      kd.warn 'Copy failed with error:', err
      @notify null, null, err

    .nodeify callback

  duplicateFiles: (nodes, callback) ->

    duplicatedNodes = []
    results = nodes.map (node) =>
      sourceItem = node.getData()
      targetItem = @nodes[sourceItem.parentPath].getData()
      sourceItem.copy(targetItem.path).then ->
        duplicatedNodes.push node

    Promise.all(results).then =>
      Tracker.track Tracker.FILETREE_DUPLICATE_FILE_FOLDER
      @notify "#{duplicatedNodes.length} item#{if duplicatedNodes.length > 1 then 's' else ''} duplicated!", 'success'

    .catch (err) =>
      kd.warn 'Duplicate file failed with error:', err
      @notify null, null, err

    .nodeify callback

  compressFiles: (nodeView, type) ->

    file = nodeView.getData()
    file.compress type, (err, response) =>
      if err then @notify null, null, err
      else
        Tracker.track Tracker.FILETREE_COMPRESS_ZIP if type is 'zip'
        Tracker.track Tracker.FILETREE_COMPRESS_TARGZ if type is 'tar.gz'
        @notify "#{file.type.capitalize()} compressed!", 'success'

  extractFiles: (nodeView) ->

    file = nodeView.getData()
    file.extract (err, response) =>
      if err then @notify null, null, err
      else
        Tracker.track Tracker.FILTREEE_EXTRACT_FILE
        @notify "#{file.type.capitalize()} extracted!", 'success'
        @refreshFolder @nodes[file.parentPath], =>
          @selectNode @nodes[response.path]

  compileApp: (nodeView, callback) ->

    folder = nodeView.getData()
    folder.emit 'fs.job.started'

    KodingAppsController.compileAppOnServer folder.path, (err, app) =>

      folder.emit 'fs.job.finished'
      return kd.warn err  if err

      @notify 'App compiled!', 'success'

      kd.utils.wait 500, =>
        @refreshFolder nodeView, =>
          kd.utils.defer =>
            @selectNode @nodes["#{folder.path}/index.js"]

      callback? err

  publishApp: (nodeView) ->

    folder = nodeView.getData()
    folder.emit 'fs.job.started'

    KodingAppsController.createJApp { path: folder.path }, (err, app) ->
      folder.emit 'fs.job.finished'

      if err or not app
        kd.warn err
        return new KDNotificationView
          title : 'Failed to publish'

      new KDNotificationView
        title: 'Published successfully!'

      kd.singletons
        .router.handleRoute "/Apps/#{app.manifest.authorNick}/#{app.name}"

  makeNewApp: (nodeView) ->
    kd.getSingleton('kodingAppsController').makeNewApp()

  cloneRepo: (nodeView) ->
    folder   = nodeView.getData()
    modal    = new CloneRepoModal
      vmName : folder.vmName
      path   : folder.path
    modal.on 'RepoClonedSuccessfully', => @notify 'Repo cloned successfully.', 'success'

  openTerminalFromHere: (nodeView) ->
    @appManager.open 'Terminal', (appInstance) =>
      path             = nodeView.getData().path
      { terminalView } = @appManager.getFrontApp().getView().tabView.getActivePane().getOptions()

      terminalView.on 'WebTermConnected', (server) ->
        server.input "cd #{path}\n"

  ###
  CONTEXT MENU OPERATIONS
  ###

  cmExpand:              (node) -> @expandFolder         node for node in @selectedNodes
  cmCollapse:            (node) -> @collapseFolder       node for node in @selectedNodes # error fix this
  cmMakeTopFolder:       (node) -> @makeTopFolder        node
  cmRefresh:             (node) -> @refreshFolder        node
  cmToggleDotFiles:      (node) -> @toggleDotFiles       node
  # cmResetVm:             (node) -> @resetVm              node
  cmUnmountVm:           (node) -> @unmountVm            node
  cmOpenMachineTerminal: (node) -> @openMachineTerminal  node
  cmCreateFile:          (node) -> @createFile           node
  cmCreateFolder:        (node) -> @createFile           node, 'folder'
  cmRename:              (node) -> @showRenameDialog     node
  cmDelete:              (node) -> @confirmDelete        node
  cmExtract:             (node) -> @extractFiles         node
  cmZip:                 (node) -> @compressFiles        node, 'zip'
  cmTarball:             (node) -> @compressFiles        node, 'tar.gz'
  cmUpload:              (node) -> @uploadFile           node
  cmOpenFile:            (node) -> @openFile             node
  cmTailFile:            (node) -> @tailFile             node
  cmPreviewFile:         (node) -> @previewFile          node
  cmCompile:             (node) -> @compileApp           node
  cmMakeNewApp:          (node) -> @makeNewApp           node
  cmPublish:             (node) -> @publishApp           node
  cmCloneRepo:           (node) -> @cloneRepo            node
  cmOpenTerminal:        (node) -> @openTerminalFromHere node
  cmDuplicate:           (node) -> @duplicateFiles       @selectedNodes
  cmDownload:            (node) -> @appManager.notify()
  cmGitHubClone:         (node) -> @appManager.notify()
  # cmOpenFileWithApp:     (node, contextMenuItem) -> @openFileWithApp  node, contextMenuItem
  # cmShowOpenWithModal: (node, contextMenuItem) -> @showOpenWithModal node
  # cmOpenFileWithApp:   (node, contextMenuItem) -> @openFileWithApp  node, contextMenuItem

  ###
  CONTEXT MENU CREATE/MANAGE
  ###

  createContextMenu: (nodeView, event) ->

    event.stopPropagation()
    event.preventDefault()
    return if nodeView.beingDeleted or nodeView.beingEdited

    if nodeView in @selectedNodes
      contextMenu = @contextMenuController.getContextMenu @selectedNodes, event
    else
      @selectNode nodeView
      contextMenu = @contextMenuController.getContextMenu [nodeView], event
    no

  contextMenuItemSelected: (nodeView, contextMenuItem) ->

    { action } = contextMenuItem.getData()
    if action
      if @["cm#{action.capitalize()}"]?
        @contextMenuController.destroyContextMenu()
      @["cm#{action.capitalize()}"]? nodeView, contextMenuItem

  ###
  RESET STATES
  ###

  resetBeingEditedItems: ->

    @beingEdited.resetView()

  organizeSelectedNodes: (listController, nodes, event = {}) ->

    @resetBeingEditedItems() if @beingEdited
    super

  ###
  DND UI FEEDBACKS
  ###

  showDragOverFeedback: (nodeView, event) -> super

  clearDragOverFeedback: (nodeView, event) -> super

  clearAllDragFeedback: -> super

  ###
  HANDLING MOUSE EVENTS
  ###

  click: (nodeView, event) ->

    return  if @isReadOnly

    if $(event.target).is '.chevron'
      @contextMenu nodeView, event
      return no

    if ($(event.target).is '.icon') and nodeView.getData().type is 'folder'
      @openItem nodeView
      return no

    super

  dblClick: (nodeView, event) ->

    return  if @isReadOnly

    @openItem nodeView


  contextMenu: (nodeView, event) ->

    return  if @isReadOnly

    if @getOptions().contextMenu
      @createContextMenu nodeView, event

  ###
  HANDLING DND
  ###

  dragOver: (nodeView, event) ->

    @showDragOverFeedback nodeView, event
    super

  dragStart: (nodeView, event) ->
    super

    @internalDragging = yes

    { name, vmName, path } = nodeView.data

    warningText = """
    You should move #{name} file to Web folder to download using drag and drop. -- Koding
    """

    type        = 'application/octet-stream'
    url         = getPublicURLOfPath path
    unless url
      url       = "data:#{type};base64,#{btoa warningText}"
      name     += '.txt'
    dndDownload = "#{type}:#{name}:#{url}"

    event.originalEvent.dataTransfer.setData 'DownloadURL', dndDownload

  lastEnteredNode = null
  dragEnter: (nodeView, event) ->

    return nodeView if lastEnteredNode is nodeView or nodeView in @selectedNodes
    lastEnteredNode = nodeView
    clearTimeout @expandTimeout
    if nodeView.getData().type in ['folder', 'mount', 'vm']
      @expandTimeout = setTimeout (=> @expandFolder nodeView), 800
    @showDragOverFeedback nodeView, event
    e = event.originalEvent

    if @boundaries.top > e.pageY > @boundaries.top + 20
      kd.log 'trigger top scroll'

    if @boundaries.top + @boundaries.height < e.pageY < @boundaries.top + @boundaries.height + 20
      kd.log 'trigger down scroll'

    super


  dragLeave: (nodeView, event) ->

    @clearDragOverFeedback nodeView, event
    super

  dragEnd: (nodeView, event) ->

    # log "clear after drag"
    @clearAllDragFeedback()
    @internalDragging = no
    super

  drop: (nodeView, event) ->

    return if nodeView in @selectedNodes
    return unless nodeView.getData?().type in ['folder', 'mount', 'machine']

    @selectedNodes = @selectedNodes.filter (node) ->
      targetPath = nodeView.getData?().path
      sourcePath = node.getData?().parentPath

      return targetPath isnt sourcePath

    if event.altKey
      @copyFiles @selectedNodes, nodeView
    else
      @moveFiles @selectedNodes, nodeView

    @internalDragging = no
    super

  ###
  HANDLING KEY EVENTS
  ###

  keyEventHappened: (event) ->

    super  unless @isReadOnly


  performDownKey: (nodeView, event) ->

    if event.altKey

      # We have to create a fakeEvent object here
      # since event.pageY/X is read-only so updating
      # offsets was not working which was causing to
      # create context menu in a wrong position when
      # altkey shortcut used
      offset    = nodeView.$('.chevron').offset()
      fakeEvent =
        pageY   : offset.top
        pageX   : offset.left
        stopPropagation : ->
        preventDefault  : ->

      @contextMenu nodeView, fakeEvent
    else
      super

  performBackspaceKey: (nodeView, event) ->

    event.preventDefault()
    event.stopPropagation()
    @confirmDelete nodeView, event
    no

  performEnterKey: (nodeView, event) ->

    @selectNode nodeView
    @openItem nodeView

  performRightKey:( nodeView, event) ->

    { type } = nodeView.getData()
    if /mount|folder|vm/.test type
      @expandFolder nodeView

  performUpKey: (nodeView, event) -> super
  performLeftKey: (nodeView, event) ->

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

  notify: (msg, style, details, reconnect = no) ->

    return unless @getView().parent?

    notification.destroy() if notification

    if details and not msg and /Permission denied/i.test details?.message
      msg = 'Permission denied!'

    style or= 'error' if details
    duration = if reconnect then 0 else if details then 5000 else 2500

    notification = new KDNotificationView
      title     : msg or 'Something went wrong'
      type      : 'finder-notification'
      cssClass  : "#{style}"
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

          kd.utils.wait 6000, notification.bound 'destroy'
          @once 'fs.retry.success', notification.bound 'destroy'
          return

        if notification.getOptions().details
          details = new KDNotificationView
            title     : 'Error details'
            content   : notification.getOptions().details
            type      : 'growl'
            duration  : 0
            click     : -> details.destroy()

          kd.getSingleton('windowController').addLayer details
          details.on 'ReceivedClickElsewhere', ->
            details.destroy()

  refreshTopNode: ->
    { nickname } = whoami().profile
    @refreshFolder @nodes["/home/#{nickname}"], =>
      Tracker.track Tracker.FILETREE_REFRESH
      @emit 'fs.retry.success'

  # showOpenWithModal: (nodeView) ->
  #   kd.getSingleton("kodingAppsController").fetchApps (err, apps) =>
  #     new OpenWithModal {}, {
  #       nodeView
  #       apps
  #     }

  uploadFile: (nodeView) ->
    finderController = @getDelegate()
    { path } = nodeView.data
    finderController.uploadTo path  if path
