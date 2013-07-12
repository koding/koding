class AppSettingsMenuButton extends KDButtonView

  getVisibleView =->
    {mainTabView} = KD.getSingleton "mainView"
    view = mainTabView.activePane?.mainView
    return view

  getCustomMenuView = (item)->
    view = getVisibleView()
    item.type = "customView"
    customMenu = view["#{item.viewName}MenuView"]? item.viewName, item
    if customMenu instanceof KDView
      customView: customMenu
    else
      customMenu

  constructor: (options = {}, data) ->

    options.cssClass = "app-settings-menu"
    options.iconOnly = yes
    options.callback = (event) =>
      menu = @getData()
      return unless menu

      @menuWidth = 172

      if menu.length is 1 and menu[0].viewName?
        [item] = menu
        menu = menuObject = getCustomMenuView item
        @menuWidth = item.width  if item.width
      else
        menuObject = {}
        menu.forEach (item, index) =>

          item.callback = (contextmenu) =>
            view = getVisibleView()
            view?.emit "#{item.eventName}MenuItemClicked", item.eventName, item, contextmenu, @offset
            @contextMenu.destroy()

          key = item.title or @utils.uniqueId("menu-item")

          if item.viewName?
            menuObject[key] = children: getCustomMenuView item
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
