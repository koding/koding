class IDE.StatusBar extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar'

    super options, data

    @status     = new KDCustomHTMLView
      cssClass  : 'status'

    @menuButton = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'actions-button'
      click     : =>
        KD.getSingleton('appManager').tell 'IDE', 'showActionsMenu', @menuButton

    @addSubView @status
    @addSubView @menuButton


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

  addDefaultMenuItems: (items, appManager) ->
    items.separator   = type: 'separator'
    items.Shortcuts   = callback: -> appManager.tell 'IDE', 'showShortcutsView'
    items.Contribute  = callback: -> KD.utils.createExternalLink 'https://github.com/koding/IDE'
    items.Quit        = callback: ->
      appManager.quitByName 'IDE'
      KD.getSingleton('router').handleRoute '/Activity'


class IDE.SyntaxSelectorMenuItem extends KDView

  constructor: (options = {}, data) ->

    options.cssClass  = 'syntax-selector'

    super options, data

    @addSubView @label  = new KDCustomHTMLView
      tagName           : 'span'
      partial           : 'Syntax'

    @addSubView @select = new KDSelectBox
      selectOptions     : IDE.settings.editor.getSyntaxOptions()
      callback          : (value) => @emit 'SelectionMade', value
