$              = require 'jquery'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
scrollToTarget = require 'app/util/scrollToTarget'

module.exports = (Component) ->

  return class ScrollableDropbox extends React.Component

    componentDidUpdate: (prevProps, prevState) ->

      { selectedIndex, selectedItem } = @props
      return  if prevProps.selectedIndex is selectedIndex or not selectedItem

      containerElement = $ '.Dropbox-scrollable:visible'
      itemElement      = containerElement.find ".DropboxItem:eq(#{selectedIndex})"

      scrollToTarget containerElement.get(0), itemElement.get(0)


    updatePosition: (inputDimensions) -> @refs.dropbox.updatePosition inputDimensions


    render: ->

      <Component ref='dropbox' {...@props} />

