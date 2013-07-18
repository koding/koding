class AppSettingsMenuButton extends KDButtonView

  getVisibleView =->
    {mainTabView} = KD.getSingleton "mainView"
    view = mainTabView.activePane?.mainView
    return view

  getCustomMenuView = (item)->
    view = getVisibleView()
    item.type = "customView"
    customMenu = view["get#{item.title.replace(/^customView/, '')}MenuView"]? item.viewName, item

  constructor: (options = {}, data) ->

    options.cssClass = "app-settings-menu"
    options.iconOnly = yes
    options.callback = (event) =>
      menu = @getData()
      return unless menu.items

      @menuWidth = menu.width or 172

      menu.items.forEach (item, index) =>

        item.children or= []
        item.callback = (contextmenu) =>
          view = getVisibleView()
          view?.emit "#{item.eventName}MenuItemClicked", item.eventName, item, contextmenu, @offset
          @contextMenu.destroy()

        if (item.title?.indexOf "customView") is 0
          customView = getCustomMenuView item
          console.log customView
          if customView instanceof KDView
            item.view = customView
          else
            menu.items = menu.items.concat JContextMenuTreeViewController.convertToArray customView, item.parentId

      @createMenu event, menu.items

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
