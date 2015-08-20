React          = require 'kd-react'
scrollToTarget = require 'activity/util/scrollToTarget'

module.exports =

  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem } = @props
    return  if prevProps.selectedItem is selectedItem or not selectedItem

    containerElement = @refs.dropup.getMainElement()
    itemElement      = React.findDOMNode @refs[@getItemKey selectedItem]

    scrollToTarget containerElement, itemElement
