kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDNotificationView = kd.NotificationView
KDTabPaneView = kd.TabPaneView
KDView = kd.View
nick = require 'app/util/nick'

FSHelper = require 'app/util/fs/fshelper'
getPublicURLOfPath = require 'app/util/getPublicURLOfPath'
ApplicationTabHandleHolder = require 'app/commonviews/applicationview/applicationtabhandleholder'
AceSettingsView = require './acesettingsview'
AceApplicationTabView = require './aceapplicationtabview'
AceView = require './aceview'

module.exports =

class AceAppView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    @aceViews            = {}
    @timestamp           = Date.now()
    @appManager          = kd.getSingleton 'appManager'
    @tabHandleContainer  = new ApplicationTabHandleHolder { delegate: this }
    @tabView             = new AceApplicationTabView
      delegate                  : this
      tabHandleContainer        : @tabHandleContainer
      closeAppWhenAllTabsClosed : no
    @finderWrapper       = new KDCustomHTMLView
      tagName            : 'aside'

    @attachEvents()
    @attachAppMenuEvents()
    @on 'PlusHandleClicked', @bound 'addNewTab'

  embedFinder: ->
    @appManager.open 'Finder', (finderApp) =>
      @finderController = finderApp.create()
      @finderWrapper.addSubView @finderController.getView()
      @finderController.reset()
      @finderController.on 'FileNeedsToBeOpened', (file) =>
        @openFile file, yes
      @openLastFiles()

  openLastFiles: ->
    new KDNotificationView { title: 'Fix lastOpenedFiles ~ GG' }

  attachEvents: ->
    @tabView.on 'PaneDidShow', (pane) ->
      { aceView } = pane.getOptions()
      return  unless aceView
      { ace }     = aceView
      return  unless ace

      ace.focus()
      ace.ready -> ace.focus()
      ace.on 'AceDidSaveAs', (name, parentPath) ->
        pane.setTitle name

      title = FSHelper.minimizePath(ace.data.path).replace /^localfile:\//, ''
      pane.tabHandle.setTitle title

    @on 'KDObjectWillBeDestroyed', ->
      kd.getSingleton('mainView').disableFullscreen()

  preview: ->
    file = @getActiveAceView().getData()
    { path, vmName } = file
    return  if /^localfile/.test path
    path = getPublicURLOfPath FSHelper.getFullPath file

    notify = =>
      @getActiveAceView().ace.notify 'File needs to be under ~/Web folder', 'error'

    if path
      match = path.match /\.kd\.io\/(.*)/
      return notify()  unless match
      path = "https://#{nick()}.kd.io/#{match[1]}"
      kd.singleton('appManager').require 'Viewer', { path, vmName }, (app) =>
        @tabView.addPane new KDTabPaneView
          name    : "[#{path.split("/").last}]"
          view    : app.getView()
    else
      notify()

  viewAppended: ->
    super
    kd.utils.wait 100, =>
      @embedFinder()
      @addNewTab() if @tabView.panes.length is 0

  addNewTab: (file) ->
    file = file or FSHelper.createFileInstance { path: 'localfile:/Untitled.txt' }
    aceView = new AceView { delegate: this, file }
    path = FSHelper.getFullPath file
    @aceViews[path] = aceView
    @setViewListeners aceView

    pane = new KDTabPaneView
      name    : file.name or 'Untitled.txt'
      aceView : aceView

    @tabView.addPane pane
    pane.addSubView aceView
    pane.on 'KDTabPaneActive', => @selectCurrentFileAtFinder aceView

    # save opened file to localStorage, so that we can open same files on refresh.
    kd.singletons.localSync.addToOpenedFiles file.path

  selectCurrentFileAtFinder: (aceView) ->
    { treeController }  = @finderController
    treeController.deselectAllNodes()
    nodeName = FSHelper.getFullPath aceView.data # we need filepath with VM address
    treeController.selectNode treeController.nodes[nodeName]

  setViewListeners: (view) ->
    @setFileListeners view.getData()

  getActiveAceView: ->
    return @tabView.getActivePane().getOptions().aceView

  isFileOpen: (file) -> @aceViews[file.path]?

  openFile: (file, isAceAppOpen) ->
    if file and @isFileOpen file
      mainTabView = kd.getSingleton('mainView').mainTabView
      mainTabView.showPane @parent
      @tabView.showPane @aceViews[file.path].parent
    else
      @addNewTab file

  removeOpenDocument: (aceView) ->
    return unless aceView
    @clearFileRecords aceView

  setFileListeners: (file) ->
    view = @aceViews[file.path]
    file.on 'fs.saveAs.finished', (newFile, oldFile) =>
      if @aceViews[oldFile.path]
        view = @aceViews[oldFile.path]
        @clearFileRecords view
        @aceViews[newFile.path] = view
        view.setData newFile
        view.parent.setTitle newFile.name
        view.ace.setData newFile
        @setFileListeners newFile
        view.ace.notify 'New file is created!', 'success'
        kd.getSingleton('mainController').emit 'NewFileIsCreated', newFile
    file.on 'fs.delete.finished', => @removeOpenDocument @aceViews[file.path]

  clearFileRecords: (view) ->
    file = view.getData()
    delete @aceViews[FSHelper.getFullPath file]

  attachAppMenuEvents: ->
    @on 'saveMenuItemClicked', => @getActiveAceView().ace.requestSave()

    @on 'saveAsMenuItemClicked', => @getActiveAceView().ace.requestSaveAs()

    @on 'saveAllMenuItemClicked', => @getActiveAceView().ace.saveAllFiles()

    @on 'previewMenuItemClicked', => @preview()

    @on 'findMenuItemClicked', => @getActiveAceView().ace.showFindReplaceView()

    @on 'findAndReplaceMenuItemClicked', => @getActiveAceView().ace.showFindReplaceView yes

    @on 'gotoLineMenuItemClicked', => @getActiveAceView().ace.showGotoLine()

    @on 'exitMenuItemClicked', =>
      @appManager.quit @appManager.frontApp
      kd.singletons.router.handleRoute '/Activity'


  getAdvancedSettingsMenuView: ->
    pane = @tabView.getActivePane()
    { aceView }  = pane.getOptions()
    settingsView = new KDView
      cssClass: 'editor-advanced-settings-menu'
    settingsView.addSubView new AceSettingsView
      delegate: aceView.ace

    return settingsView

  getRecentsMenuView: ->
    items = @createSessionListItems()
    unless Object.keys(items).length
      return new KDView
        partial: '<cite>No recently opened file exists.</cite>'
    return items

  getFullscreenMenuView: (item, menu) ->
    labels = [
      'Enter Fullscreen'
      'Exit Fullscreen'
    ]
    mainView = kd.getSingleton 'mainView'
    state    = mainView.isFullscreen() or 0
    toggleFullscreen = new KDView
      partial : "<span>#{labels[Number state]}</span>"
      click   : =>
        @getActiveAceView().toggleFullscreen()
        menu.contextMenu.destroy()
        menu.click()
    # behave like a menu item
    toggleFullscreen.on 'viewAppended', ->
      toggleFullscreen.parent.setClass 'default'

  pistachio: ->
    '''
      {{> @finderWrapper}}
      <section>
      {{> @tabHandleContainer}}
      {{> @tabView}}
      </section>
    '''
