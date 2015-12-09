React          = require 'kd-react'
ReactDOM       = require 'react-dom'
scrollToTarget = require 'app/util/scrollToTarget'


module.exports = DropboxWrapperMixin =

  isActive: ->

    { items, visible } = @props
    visible ?= yes
    return items.size > 0 and visible


  hasSingleItem: -> @props.items.size is 1


  confirmSelectedItem: ->

    @handleSelectedItemConfirmation?()

    selectedValue = @formatSelectedValue()
    @props.onItemConfirmed? selectedValue
    @close()


  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem, visible } = @props

    return  if prevProps.selectedItem is selectedItem or not selectedItem
    return  if visible? and not visible

    containerElement = @refs.dropbox.getContentElement()
    itemElement      = ReactDOM.findDOMNode @refs[@getItemKey selectedItem]

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


  updatePosition: (inputDimensions) -> @refs.dropbox.setInputDimensions inputDimensions

