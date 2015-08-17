module.exports =

  isActive: ->

    { items, visible } = @props
    visible ?= yes
    return items.size > 0 and visible


  hasOnlyItem: -> @props.items.size is 1


  confirmSelectedItem: ->

    selectedValue = @formatSelectedValue()
    @props.onItemConfirmed? selectedValue
    @close()


  moveToNextPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      @requestNextIndex()
      return yes


  moveToPrevPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      @requestPrevIndex()
      return yes
