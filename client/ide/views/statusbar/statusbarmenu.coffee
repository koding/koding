class IDE.StatusBarMenu extends KDContextMenu

  constructor: (options = {}) ->

    menuItems         = @getMenuItems options.paneType
    {delegate}        = options
    options.menuWidth = 220
    options.x         = delegate.getX()
    options.cssClass  = 'status-bar-menu'

    super options, menuItems

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      if event.target.classList.contains 'kdlistitemview'
        @destroy()

  getMenuItems: (paneType) ->
    appManager = KD.getSingleton 'appManager'
    items      = {}

    @addEditorMenuItems  items, appManager  if paneType is 'editor'
    @addDefaultMenuItems items, appManager

    return items

  addEditorMenuItems: (items, appManager) ->
    items.Save        = callback: -> appManager.tell 'IDE', 'saveFile'
    items['Save All'] = callback: -> appManager.tell 'IDE', 'saveAllFiles'
    items.customView  = @syntaxSelector = new IDE.SyntaxSelectorMenuItem
    items.separator   = type: 'separator'

  addDefaultMenuItems: (items, appManager) ->
    mainView = KD.getSingleton 'mainView'
    fsText   = if mainView.isFullscreen() then 'Exit' else 'Enter'

    items.Shortcuts  = callback: -> appManager.tell 'IDE', 'showShortcutsView'
    items["#{fsText} Fullscreen"] = callback: -> mainView.toggleFullscreen()
    items.Contribute = callback: -> KD.utils.createExternalLink 'https://github.com/koding/IDE'
    items.Quit       = callback: ->
      appManager.quitByName 'IDE'
      mainView.toggleFullscreen()  if mainView.isFullscreen()
      KD.getSingleton('router').handleRoute '/Activity'
