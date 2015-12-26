$            = require 'jquery'
kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
classnames   = require 'classnames'
Dropbox      = require './dropboxbody'
KeyboardKeys = require 'app/constants/keyboardKeys'

module.exports = class RelativeDropbox extends React.Component

  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'
    document.addEventListener 'keydown', @bound 'handleKeyDown'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'
    document.removeEventListener 'keydown', @bound 'handleKeyDown'


  componentDidUpdate: ->

    return  unless @props.visible
    return  unless @props.direction is 'up'

    dropbox = $ ReactDOM.findDOMNode @refs.dropbox
    dropbox.css top : -element.outerHeight()


  getContentElement: -> @refs.dropbox.getContentElement()


  handleMouseClick: (event) ->

    { visible, onClose } = @props

    return  unless visible

    { target } = event
    dropbox    = ReactDOM.findDOMNode this
    innerClick = $.contains dropbox, target

    onClose?()  unless innerClick


  handleKeyDown: (event) ->

    { visible, onClose } = @props

    return  unless @props.visible

    onClose?()  if event.which is KeyboardKeys.ESC


  render: ->

    { visible } = @props

    className = classnames
      'Dropbox-container' : yes
      'hidden'            : not visible

    <div className={className}>
      <Dropbox {...@props} ref='dropbox'>
        { @props.children }
      </Dropbox>
    </div>

