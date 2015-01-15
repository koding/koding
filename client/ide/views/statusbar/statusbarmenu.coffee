StatusBarMenuItem      = require './statusbarmenuitem'
SyntaxSelectorMenuItem = require './syntaxselectormenuitem'


class StatusBarMenu extends KDContextMenu

  constructor: (options = {}) ->

    menuItems             = @getMenuItems options
    {delegate}            = options
    options.menuWidth     = 220
    options.x             = delegate.getX() - 5
    options.y             = delegate.getY() + 20
    options.cssClass      = 'status-bar-menu'
    options.treeItemClass = StatusBarMenuItem

    super options, menuItems

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      unless event.target.parentNode.classList.contains 'kdselectbox'
        @destroy()

  getMenuItems: ->
    isNavigatorApple = KD.utils.isNavigatorApple()

    @syntaxSelector = new SyntaxSelectorMenuItem

    list = [
      # name                   # shortcut      # cmd
      [ 'Save'               , 'Meta+S'      , 'saveFile' ]
      [ 'Save As...'         , 'Meta+Shift+S', 'saveAs' ]
      [ 'Save All'           , 'Ctrl+Alt+S'  , 'saveAllFiles' ]
      [ 'Syntax'             , @syntaxSelector ]
      [ 'Preview'            , 'Ctrl+Alt+P'  , 'previewFile' ]
      [ 'Find...'            , 'Meta+F'      , 'showFindReplaceView' ]
      [ 'Find and replace...', 'Meta+Shift+F', 'showFindReplaceViewWithReplaceMode' ]
      [ 'Find in files...'   , 'Ctrl+Alt+F'  , 'showContentSearch' ]
      [ 'Jump to file...'    , 'Ctrl+Alt+O'  , 'showFileFinder' ]
      [ 'Go to line...'      , 'Meta+G'      , 'goToLine' ]
    ]

    # it is safe to display unicode definitions on mac
    macKeysUnicodeMapping =
      'Shift': '&#x21E7;'
      'Meta' : '&#x2318;'
      'Alt'  : '&#x2325;'
      'Ctrl' : '^'

    winKeysMapping =
      'Meta': 'Ctrl'

    appManager = KD.getSingleton 'appManager'

    items = {}

    while (item = list.shift())?
      isCustomView = typeof item[1] isnt 'string'
      key = item[0]

      unless isCustomView

        if isNavigatorApple
          for own k, v of macKeysUnicodeMapping
            item[1] = item[1].replace(k, v)
          # by tradition osx is not displaying + for shortcuts
          item[1] = item[1].replace(/\+/g, '')
        else
          for own k, v of winKeysMapping
            item[1] = item[1].replace(k, v)

        items[key] =
          shortcut: item[1]
          callback: appManager.tell.bind appManager, 'IDE', item[2]

      else
        items[key] =
          type: 'customView'
          view: item[1]

    return items


module.exports = StatusBarMenu
