class NavigationList extends KDListView

  constructor:->
    super

    @viewWidth = 55

    # @on 'ItemWasAdded', (view)=>

    #   view.once 'viewAppended', =>

    #     if view.data.type is 'persistent'
    #       view.options.draggable = axis : 'x'

    #     view._index ?= @getItemIndex view
    #     view.setX view._index * @viewWidth
    #     @_width = @viewWidth * (@items.length + 1)
    #     @setWidth @_width - @viewWidth
    #     KD.utils.defer -> view.unsetClass 'no-anim'

    #   lastChange = 0

    #   view.on 'DragStarted', =>
    #     @_dragStarted = yes

    #   view.on 'DragInAction', (x, y)=>

    #     if @_dragStarted and y > 15 and view.data.type isnt 'persistent'
    #       dock = KD.singletons.dock.mainView
    #       dock.setClass 'remove-app-state'
    #       delete @_dragStarted

    #     return  if x + view._x > @_width or x + view._x < 0

    #     if view.data.type isnt 'persistent' and y > 25
    #     then view.setClass 'remove'
    #     else view.unsetClass 'remove'

    #     if x > @viewWidth
    #       current = Math.floor x / @viewWidth
    #     else if x < -@viewWidth
    #       current = Math.ceil  x / @viewWidth
    #     else
    #       current = 0

    #     if current > lastChange
    #       @moveItemToIndex view, view._index+1
    #       lastChange = current
    #     else if current < lastChange
    #       @moveItemToIndex view, view._index-1
    #       lastChange = current

    #   view.on 'DragFinished', =>

    #     view.unsetClass 'no-anim remove'

    #     if view.data.type isnt 'persistent' and view.getRelativeY() > 25

    #       view.setClass 'explode'
    #       KD.utils.wait 500, => @removeApp view

    #     else

    #       KD.utils.wait 200, -> view.unsetClass 'on-top'
    #       view.setX view._index * @viewWidth
    #       view.setY 0

    #       KD.singletons.dock.saveItemOrders @items

    #     lastChange  = 0

    #     KD.utils.wait 200, =>
    #       delete @_dragStarted
    #       KD.singletons.dock.mainView.unsetClass 'remove-app-state'


  removeApp:(view)->

    @removeItem view
    @updateItemPositions()
    KD.singletons.dock.removeItem view

  updateItemPositions:(excluded)->

    @_width = @viewWidth * (@items.length + 1)
    @setWidth @_width - @viewWidth

    for _item, index in @items
      _item._index = index
      _item.setX index * @viewWidth  unless _item is excluded

  moveItemToIndex:(item, index)->
    super item, index
    @updateItemPositions item
