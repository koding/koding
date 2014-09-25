class IDE.StatusBarMenu extends KDContextMenu

  constructor: (options = {}) ->

    menuItems         = @getMenuItems options
    {delegate}        = options
    options.menuWidth = 220
    options.x         = delegate.getX() - 5
    options.y         = delegate.getY() + 20
    options.cssClass  = 'status-bar-menu'

    super options, menuItems

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      if event.target.classList.contains 'kdlistitemview'
        @destroy()

  getMenuItems: (options) ->
    appManager = KD.getSingleton 'appManager'
    items      = {}
    items.Save                   = callback: -> appManager.tell 'IDE', 'saveFile'
    items['Save As...']          = callback: -> appManager.tell 'IDE', 'saveAs'
    items['Save All']            = callback: -> appManager.tell 'IDE', 'saveAllFiles'
    items.customView             = @syntaxSelector = new IDE.SyntaxSelectorMenuItem
    items.Preview                = callback: -> appManager.tell 'IDE', 'previewFile'
    items['Find...']             = callback: -> appManager.tell 'IDE', 'showFindReplaceView'
    items['Find and replace...'] = callback: -> appManager.tell 'IDE', 'showFindReplaceView', yes
    items['Find in files...']    = callback: -> appManager.tell 'IDE', 'showContentSearch'
    items['Jump to file...']     = callback: -> appManager.tell 'IDE', 'showFileFinder'
    items['Go to line...']       = callback: -> appManager.tell 'IDE', 'goToLine'

    return items
