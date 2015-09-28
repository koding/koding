React          = require 'kd-react'
scrollToTarget = require 'app/util/scrollToTarget'


module.exports = DropboxWrapperMixin =

  isActive: ->

    { items, visible } = @props
    visible ?= yes
    return items.size > 0 and visible


  hasSingleItem: -> @props.items.size is 1


  confirmSelectedItem: ->

    selectedValue = @formatSelectedValue()
    @props.onItemConfirmed? selectedValue
    @close()


  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem } = @props

    return  if prevProps.selectedItem is selectedItem or not selectedItem

    containerElement = @refs.dropbox.getMainElement()
    itemElement      = React.findDOMNode @refs[@getItemKey selectedItem]

    scrollToTarget containerElement, itemElement


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    @moveToPrevAction()  unless @hasSingleItem()
    return yes


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    @moveToNextAction()  unless @hasSingleItem()
    return yes


  onItemSelected: (index) -> @onItemSelectedAction index


  close: -> @closeAction no


  getItemKey: (item) -> item.get 'id'

