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

        # if item has parent then add "children" to the parents.
        if item.parentId
          parents = _.filter menu.items, (menuItem)-> menuItem.id is item.parentId
          parents.forEach (parentItem) -> parentItem.children or= []

        item.callback = (contextmenu) =>
          view = getVisibleView()
          view?.emit "#{item.eventName}MenuItemClicked", item.eventName, item, contextmenu, @offset
          return unless item.eventName
          @contextMenu.destroy()

        if (item.title?.indexOf "customView") is 0
          customView = getCustomMenuView item
          if customView instanceof KDView
            item.view = customView
          else
            childItems = JContextMenuTreeViewController.convertToArray customView, item.parentId
            # escaping the items appended before
            menuWithoutChilds = _.filter menu.items, (menuItem) -> menuItem.parentId isnt item.parentId
            menu.items = menuWithoutChilds.concat childItems

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
