class AppSettingsMenuButton extends KDButtonView

  getVisibleView =->
    {mainTabView} = KD.getSingleton "mainView"
    view = mainTabView.activePane?.mainView
    return view

  getCustomMenuView = (item, obj)->
    view = getVisibleView()
    item.type = "customView"
    customMenu = view["get#{item.title.replace(/^customView/, '')}MenuView"]? item, obj

  constructor: (options = {}, data) ->

    options.cssClass = "app-settings-menu"
    options.iconOnly = yes
    options.callback = (event) =>
      menu = @getData()
      return unless menu.items

      @menuWidth = menu.width or 172

      menuItems = menu.items.filter (item, index) =>

        # if item has parent then add "children" to the parents.
        if item.parentId
          parents = _.filter menu.items, (menuItem)-> menuItem.id is item.parentId
          parents.forEach (parentItem) -> parentItem.children or= []

        if item.condition
          response = item.condition getVisibleView()
          return unless response

        item.callback = (contextmenu) =>
          view = getVisibleView()
          view?.emit "#{item.eventName}MenuItemClicked", item.eventName, item, contextmenu, @offset
          return unless item.eventName
          @contextMenu.destroy()

        if (item.title?.indexOf "customView") is 0
          customView = getCustomMenuView item, this
          return  unless customView
          if customView instanceof KDView
            item.view = customView
          else
            childItems = JContextMenuTreeViewController.convertToArray customView, item.parentId
            # escaping the items appended before
            menuWithoutChilds = _.filter menu.items, (menuItem) -> menuItem.parentId isnt item.parentId
            menu.items = menuWithoutChilds.concat childItems

        return item

      if menuItems.length > 0
        @createMenu event, menuItems

    super options, data

  createMenu: (event, menu) ->
    @offset = @$().offset()
    @contextMenu = new JContextMenu
      cssClass    : "app-settings"
      delegate    : @
      x           : @offset.left - @menuWidth - 3
      y           : @offset.top + 8
      arrow       :
        placement : "right"
        margin    : 5
    , menu
    @contextMenu.on "viewAppended", =>
      @contextMenu.setWidth @menuWidth  if @menuWidth > 172
