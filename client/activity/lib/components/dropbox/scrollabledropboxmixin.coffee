React          = require 'kd-react'
ReactDOM       = require 'react-dom'
scrollToTarget = require 'app/util/scrollToTarget'

module.exports = ScrollableDropboxMixin =

  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem } = @props

    return  if prevProps.selectedItem is selectedItem or not selectedItem

    containerElement = @refs.dropbox.getContentElement()
    itemElement      = ReactDOM.findDOMNode @refs[@getItemKey selectedItem]

    scrollToTarget containerElement, itemElement

