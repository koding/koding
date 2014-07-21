class IDE.StatusBarMenu extends KDContextMenu

  constructor: (options = {}) ->

    menuItems         = @getMenuItems options
    {delegate}        = options
    options.menuWidth = 220
    options.x         = delegate.getX()
    options.cssClass  = 'status-bar-menu'

    super options, menuItems

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      if event.target.classList.contains 'kdlistitemview'
        @destroy()

  getMenuItems: (options) ->
    appManager = KD.getSingleton 'appManager'
    items      = {}

    @addEditorMenuItems  items, options, appManager  if options.paneType is 'editor'
    @addDefaultMenuItems items, options, appManager

    return items

  addEditorMenuItems: (items, options, appManager) ->
    items.Save                = callback: -> appManager.tell 'IDE', 'saveFile'
    items['Save As...']       = callback: -> appManager.tell 'IDE', 'saveAs'
    items['Save All']         = callback: -> appManager.tell 'IDE', 'saveAllFiles'
    items.customView          = @syntaxSelector = new IDE.SyntaxSelectorMenuItem
    items.Preview             = callback: -> appManager.tell 'IDE', 'previewFile'
    items['More...']          =
      children                :
        'Find...'             :
          callback            : -> appManager.tell 'IDE', 'showFindReplaceView'
        'Find and replace...' :
          callback            : -> appManager.tell 'IDE', 'showFindReplaceView', yes
        'Find in files...'    :
          callback            : -> appManager.tell 'IDE', 'showContentSearch'
        'Jump to file...'     :
          callback            : -> appManager.tell 'IDE', 'showFileFinder'

    items.separator   = type: 'separator'

  addDefaultMenuItems: (items, options, appManager) ->
    mainView = KD.getSingleton 'mainView'
    fsText   = if mainView.isFullscreen() then 'Exit' else 'Enter'

    items.Shortcuts  = callback: -> appManager.tell 'IDE', 'showShortcutsView'
    items["#{fsText} Fullscreen"] = callback: ->
      mainView.toggleFullscreen()
      appManager.tell 'IDE', 'doResize'
    items.Contribute = callback: -> KD.utils.createExternalLink 'https://github.com/koding/IDE'
    items.Quit       = callback: ->
      appManager.quitByName 'IDE'
      mainView.toggleFullscreen()  if mainView.isFullscreen()
      KD.getSingleton('router').handleRoute '/Activity'
