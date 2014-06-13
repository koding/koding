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

    menuItems        = @getMenuItems options.paneType
    {delegate}       = options
    options.x        = delegate.getX()
    options.cssClass = 'status-bar-menu'

    super options, menuItems

    @on 'ContextMenuItemReceivedClick', @bound 'destroy'

  getMenuItems: (paneType) ->
    appManager = KD.getSingleton 'appManager'
    items      = {}

    if paneType is 'editor'
      items.Save            = callback: -> appManager.tell 'IDE', 'saveFile'
      items['Save All']     =
        callback            : -> appManager.tell 'IDE', 'saveAllFiles'
        separator           : yes

    items['Show Shortcuts'] = callback: -> appManager.tell 'IDE', 'showShortcutsView'
    items.Contribute        = callback: ->
      KD.utils.createExternalLink 'https://github.com/koding/IDE'
    items.Quit              = callback: ->
      appManager.quitByName 'IDE'
      KD.getSingleton('router').handleRoute '/Activity'

    return items
