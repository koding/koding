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
          @moveItemsTemporarily view, 1
          lastChange = current
        else if current < lastChange
          @moveItemsTemporarily view, -1
          lastChange = current

      view.on 'DragFinished', =>
        view.setX view._index * @viewWidth
        @moveItemToIndex view, view._index
        item._index = i for item, i in @items
        lastChange  = 0

  moveItemsTemporarily:(view, step)->

    newIndex = Math.max(0, Math.min(view._index + step, @items.length-1))
    return  if newIndex is view._index

    for item, index in @items
      if item._index is newIndex
        item.setX item.getRelativeX() - (step * @viewWidth)
        item._index = view._index
        view._index = newIndex
        break
