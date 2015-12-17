React          = require 'kd-react'
ReactDOM       = require 'react-dom'
scrollToTarget = require 'app/util/scrollToTarget'

module.exports = (Component) ->

  class ScrollableDropbox extends React.Component

    componentDidUpdate: (prevProps, prevState) ->

      { selectedItem } = @props

      return  if prevProps.selectedItem is selectedItem or not selectedItem

      containerElement = document.querySelector '.Dropbox-contentWrapper'
      itemElement      = ReactDOM.findDOMNode @refs[@getItemKey selectedItem]

      scrollToTarget containerElement, itemElement


    render: ->

      <Component {...@props} />


  return ScrollableDropbox

