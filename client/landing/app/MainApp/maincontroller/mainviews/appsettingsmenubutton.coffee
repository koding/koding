class AppSettingsMenuButton extends KDButtonView

  getVisibleView =->
    {mainTabView} = KD.getSingleton "mainView"
    view = mainTabView.activePane?.mainView
    return view

  constructor: (options = {}, data) ->

    options.cssClass = "app-settings-menu"
    options.iconOnly = yes
    options.callback = (event) =>
      menu = @getData()
      return unless menu
      view = getVisibleView()

      @menuWidth = 172

      if menu.length is 1 and menu[0].type == "customView"
        [item] = menu
        item.viewName or= ""
        menu = menuObject = customView: view["#{item.viewName}MenuView"]? item.viewName, item
        @menuWidth = item.width  if item.width
      else
        menuObject = {}
        menu.forEach (item, index) =>
          item.closeMenuWhenClicked ?= yes

          item.callback = (contextmenu) =>
            view?.emit "#{item.eventName}MenuItemClicked", item.eventName, item, contextmenu, @offset
            @contextMenu.destroy() if item.closeMenuWhenClicked

          key = item.title or @utils.uniqueId("menu-item")

          if item.type is "customView"
            item.viewName or= ""
            menuObject[key] = children: customView: view["#{item.viewName}MenuView"]? item.viewName, item
          else
            menuObject[key] = item

      @createMenu event, menuObject

    super options, data

  createMenu: (event, menu) ->
    @offset = @$().offset()
    @contextMenu = new JContextMenu
      delegate    : @
      x           : @offset.left - @menuWidth - 3
      y           : @offset.top - 6
      arrow       :
        placement : "right"
        margin    : 5
    , menu
    @contextMenu.setWidth @menuWidth  if @menuWidth > 172
