#FIXME: Can't these methods be used in the general KDListView? -sah
class KDAutoCompleteListView extends KDListView
  constructor:(options,data)->
    super options,data
    @setClass "kdautocompletelist"

  # keyDown:(autoCompleteView,event)=>
  #   switch event.which
  #     when 13 #enter
  #       # @submitAutoComplete autoCompleteView.getValue()
  #     when 27 #escape
  #       # @hideDropdown()
  #     when 38 #uparrow
  #       @goUp()
  #       # @getView().$input().blur()
  #     when 40 #downarrow
  #       @goDown()
  #       # @getView().$input().blur()
  #   no
  goDown:->
    activeItem = @getActiveItem()
    if activeItem.index?
      nextItem = @items[activeItem.index+1]
      if nextItem?
        nextItem.makeItemActive()
    else
      @items[0]?.makeItemActive()

  goUp:->
    activeItem = @getActiveItem()
    if activeItem.index?
      if @items[activeItem.index-1]?
        @items[activeItem.index-1].makeItemActive()
      else
        @emit 'ItemsDeselected'
    else
      @items[0].makeItemActive()

  getActiveItem:->
    active =
      index : null
      item  : null
    for item,i in @items
      if item.active
        active.item  = item
        active.index = i
        break
    active
