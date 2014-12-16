class IDE.StatusBarMenu extends KDContextMenu

  constructor: (options = {}) ->

    menuItems             = @getMenuItems options
    {delegate}            = options
    options.menuWidth     = 220
    options.x             = delegate.getX() - 5
    options.y             = delegate.getY() + 20
    options.cssClass      = 'status-bar-menu'
    options.treeItemClass = IDE.StatusBarMenuItem

    super options, menuItems

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      if event.target.classList.contains 'kdlistitemview'
        @destroy()

  getMenuItems: ->
    isNavigatorApple = utils.isNavigatorApple()

    @syntaxSelector = new IDE.SyntaxSelectorMenuItem

    list = [
      # name                   # shortcut      # cmd
      [ 'Save'               , 'Meta+S'      , 'saveFile' ],
      [ 'Save As...'         , 'Meta+Shift+S', 'saveAs' ],
      [ 'Save All'           , 'Ctrl+Alt+S'  , 'saveAllFiles' ],
      @syntaxSelector,
      [ 'Preview'            , 'Ctrl+Alt+P'  , 'previewFile' ],
      [ 'Find...'            , 'Meta+F'      , 'showFindReplaceView' ],
      [ 'Find and replace...', 'Meta+Shift+F', 'showFindReplaceViewWithReplaceMode' ],
      [ 'Find in files...'   , 'Ctrl+Alt+F'  , 'showContentSearch' ],
      [ 'Jump to file...'    , 'Ctrl+Alt+O'  , 'showFileFinder' ],
      [ 'Go to line...'      , 'Meta+G'      , 'goToLine' ]
    ]

    # it is safe to display unicode definitions on mac
    macKeysUnicodeMapping = {
      'Shift': '&#x21E7;',
      'Meta' : '&#x2318;',
      'Alt'  : '&#x2325;',
      'Ctrl' : '^'
    }

    winKeysMapping = {
      'Meta': 'Ctrl'
    }

    appManager = KD.getSingleton 'appManager'

    items = {}
    while (item = list.shift())?
      if item is @syntaxSelector
        items.customView = @syntaxSelector
        continue
      if isNavigatorApple
        for k, v of macKeysUnicodeMapping
          item[1] = item[1].replace(k, v)
        # by tradition osx is not displaying + for shortcuts
        item[1] = item[1].replace(/\+/g, '')
      else
        for k, v of winKeysMapping
          item[1] = item[1].replace(k, v)
      key = "#{item[0]}$#{item[1]}" # $ is being used as the separator
      items[key] = callback: appManager.tell.bind appManager, 'IDE', item[2]

    return items
