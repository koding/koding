class NavigationList extends KDListView

  constructor:->
    super

    @viewWidth = 55

    @on 'ItemWasAdded', (view)=>

      view.once 'viewAppended', =>

        view._index ?= @getItemIndex view
        view.setX view._index * @viewWidth
        @_width = @viewWidth * (@items.length + 1)
        @setWidth @_width - @viewWidth
        KD.utils.defer -> view.unsetClass 'no-anim'

      lastChange = 0

      view.on 'DragStarted', =>
        @_dragStarted = yes

      view.on 'DragInAction', (x, y)=>

        if @_dragStarted and y > 25
          dock = KD.singletons.dock.mainView
          dock.setClass 'in-order'
          dock.setClass 'removable'  unless view.data.type is 'persistent'
          delete @_dragStarted

        return  if x + view._x > @_width or x + view._x < 0

        if view.data.type isnt 'persistent' and y > 125
        then view.setClass 'remove'
        else view.unsetClass 'remove'

        if x > @viewWidth
          current = Math.floor x / @viewWidth
        else if x < -@viewWidth
          current = Math.ceil  x / @viewWidth
        else
          current = 0

        if current > lastChange
          @moveItemToIndex view, view._index+1
          lastChange = current
        else if current < lastChange
          @moveItemToIndex view, view._index-1
          lastChange = current

      view.on 'DragFinished', =>

        view.unsetClass 'no-anim remove'

        if view.data.type isnt 'persistent' and view.getY() > 100

          view.setClass 'explode'
          KD.utils.wait 500, => @removeApp view

        else

          KD.utils.wait 200, -> view.unsetClass 'on-top'
          view.setX view._index * @viewWidth
          view.setY 0

          KD.singletons.dock.saveItemOrders @items

        lastChange  = 0

        KD.utils.wait 200, =>
          delete @_dragStarted
          KD.singletons.dock.mainView.unsetClass 'in-order removable'


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
