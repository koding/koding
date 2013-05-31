class AppSettingsMenuButton extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = "app-settings-menu"
    options.iconOnly = yes
    options.callback = (event) =>
      menu = @getData()
      return unless menu

      {mainTabView} = KD.getSingleton "mainView"
      menu.forEach (item, index) =>
        item.closeMenuWhenClicked ?= yes

        item.callback = (contextmenu) =>
          view = mainTabView.activePane?.mainView
          item.eventName or= item.title
          view?.emit "#{item.eventName}MenuItemClicked", item.eventName, item, contextmenu, @offset
          @contextMenu.destroy() if item.closeMenuWhenClicked

      @createMenu event, menu

    super options, data

  createMenu: (event, menu) ->
    @offset = @$().offset()
    @contextMenu = new JContextMenu
      delegate    : @
      x           : @offset.left - 150
      y           : @offset.top + 20
      arrow       :
        placement : "top"
        margin    : -5
    , menu
