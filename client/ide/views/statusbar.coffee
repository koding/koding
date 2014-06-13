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

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar-menu'
    data = @getMenuItems options.paneType

    super options, data

    @on 'ContextMenuItemReceivedClick', @bound 'destroy'

  getMenuItems: (paneType) ->
    appManager = KD.getSingleton 'appManager'
    items      = {}

    items.Shortcuts  = callback: -> appManager.tell 'IDE', 'showShortcutsView'
    items.Feedback   = callback: -> appManager.tell 'IDE', 'showFeedbackView'
    items.Contribute = callback: -> appManager.tell 'IDE', 'showContributeView'
    items.Quit       = callback: ->
      appManager.quitByName 'IDE'
      KD.getSingleton('router').handleRoute '/Activity'

    return items
