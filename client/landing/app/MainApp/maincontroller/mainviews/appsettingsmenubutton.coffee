class AppSettingsMenuButton extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = "app-settings-menu"
    options.iconOnly = yes
    options.callback = (event) =>
      menu = @getData()
      return unless menu

      {mainTabView} = KD.getSingleton "mainView"
      menu.forEach (item, index) =>

        item.callback = (contextmenu) =>
          view = mainTabView.activePane?.mainView
          item.eventName or= item.title
          view?.emit "menu.#{item.eventName}", item.eventName, item, contextmenu
          @contextMenu.destroy()

      @createMenu event, menu

    super options, data

  createMenu: (event, menu) ->
    offset = @$().offset()
    @contextMenu = new JContextMenu
      event       : event
      delegate    : @
      x           : offset.left - 150
      y           : offset.top + 20
      arrow       :
        placement : "top"
        margin    : -5
    , menu
