class NavigationList extends KDListView

  constructor:->
    super

    @viewWidth = 70

    @on 'ItemWasAdded', (view)=>

      view.once 'viewAppended', =>

        view._index ?= @getItemIndex view
        view.setX view._index * @viewWidth
        @_width = @viewWidth * @items.length

  #   if data.promote
  #     options.childClass = NavigationPromoteLink
  #     return options

  #   if data.type is "separator"
  #     options.childClass = NavigationSeparator
  #     options.selectable = no
  #     return options

  #   if data.type is "admin"
  #     options.itemClass  = AdminNavigationLink
  #     options.selectable = no
  #     return options
