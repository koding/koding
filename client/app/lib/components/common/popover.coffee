kd        = require 'kd'
React     = require 'app/react'
Portal    = require 'react-portal'
ReactDOM  = require 'react-dom'

require './styl/popover.styl'


module.exports = class Popover extends React.Component

  @defaultProps =
    isOpened            : yes
    closeOnEsc          : yes
    onClose             : kd.noop
    closeOnOutsideClick : yes
    coordinates         : { top: 0, left: 0 }


  setCoordinates: ->

    popover = ReactDOM.findDOMNode @refs.Popover

    if popover
      popover.style.top   = "#{@props.coordinates.top - 15}px"
      popover.style.left  = "#{@props.coordinates.left + 15}px"


  componentDidUpdate: -> @setCoordinates()


  componentDidMount: -> @setCoordinates()


  render: ->

    <Portal {...@props}>
      <div className={kd.utils.curry 'Popover', @props.className}>
        <div className="Popover-Wrapper" ref='Popover'>{@props.children}</div>
      </div>
    </Portal>
