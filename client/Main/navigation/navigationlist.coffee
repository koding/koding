class NavigationList extends KDListView

  constructor:->
    super

    @viewWidth = 55

    @on 'ItemWasAdded', (view)=>

      view.once 'viewAppended', =>

        view._index ?= @getItemIndex view
        view.setX view._index * @viewWidth
        @_width = @viewWidth * @items.length

      lastChange = 0

      view.on 'DragInAction', (x, y)=>

        return  if x + view._x > @_width or x + view._x < 0

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
        view.setX view._index * @viewWidth
        view.setY 0
        lastChange  = 0

  moveItemToIndex:(item, index)->
    super item, index

    for _item, index in @items
      _item._index = index
      _item.setX index * @viewWidth  unless item is _item
