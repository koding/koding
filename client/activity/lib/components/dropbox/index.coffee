$            = require 'jquery'
kd           = require 'kd'
React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
KeyboardKeys = require 'app/util/keyboardKeys'

module.exports = class Dropbox extends React.Component

  @defaultProps =
    visible   : no
    className : ''
    type      : 'dropdown'


  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'
    document.addEventListener 'keydown', @bound 'handleKeyDown'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'
    document.removeEventListener 'keydown', @bound 'handleKeyDown'


  getContentElement: -> React.findDOMNode @refs.content


  handleMouseClick: (event) ->

    { visible, onClose } = @props

    return  unless visible

    { target } = event
    dropbox    = React.findDOMNode this
    innerClick = $.contains dropbox, target

    onClose?()  unless innerClick


  handleKeyDown: (event) ->

    { visible, onClose } = @props

    return  unless @props.visible

    onClose?()  if event.which is KeyboardKeys.ESC


  getClassName: ->

    { className, type } = @props

    classes =
      'Reactivity' : yes
      'Dropbox'    : yes
      'Dropup'     : type is 'dropup'
      'Dropdown'   : type is 'dropdown'
    classes[className] = yes  if className

    return classnames classes


  renderSubtitle: ->

    { subtitle } = @props
    return  unless subtitle

    <span className="Dropbox-subtitle">{ subtitle }</span>


  renderHeader: ->

    { title } = @props
    return unless title

    <div className='Dropbox-header'>
      { title }
      { @renderSubtitle() }
    </div>


  render: ->

    { visible } = @props

    className = @getClassName()
    <div className={className} ref='dropbox'>
      { @renderHeader() }
      <div className='Dropbox-scrollable' ref='content'>
        <div className='Dropbox-content'>
          { @props.children }
        </div>
      </div>
    </div>

