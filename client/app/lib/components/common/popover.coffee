kd        = require 'kd'
React     = require 'kd-react'
Portal    = require('react-portal').default
ReactDOM  = require 'react-dom'


module.exports = class Popover extends React.Component

  @defaultProps =
    isOpened            : yes
    closeOnEsc          : no
    onClose             : kd.noop
    closeOnOutsideClick : yes
    coordinates         : { top: 0, left: 0 }


  setCoordinates: ->

    popover = ReactDOM.findDOMNode @refs.Popover
    popover.style.top = "#{@props.coordinates.top}px"
    popover.style.left = "#{@props.coordinates.left}px"


  componentDidUpdate: -> @setCoordinates()


  componentDidMount: -> @setCoordinates()


  render: ->

    <Portal {...@props} className={kd.utils.curry 'Popover', @props.className}>
      <div className="Popover-Wrapper" ref='Popover'>{@props.children}</div>
    </Portal>
