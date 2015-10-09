$            = require 'jquery'
kd           = require 'kd'
React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Portal       = require 'react-portal'

module.exports = class Dropbox extends React.Component

  @defaultProps =
    visible   : no
    className : ''
    direction : 'down'


  getContentElement: -> React.findDOMNode @refs.content


  setPosition: (inputDimensions) ->

    { visible, direction } = @props

    return  unless visible

    element = $ React.findDOMNode @refs.dropbox
    { width, height, top, left } = inputDimensions

    if direction is 'up'
      height = $(window).height()
      css = { left, width, bottom : height - top }
    else
      css = { left, width, top : top + height }

    element.css css


  getClassName: ->

    { className } = @props

    classes =
      'Dropbox' : yes
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

    { visible, onClose } = @props

    className = @getClassName()
    <Portal isOpened={visible} closeOnEsc=yes closeOnOutsideClick=yes onClose={onClose}>
      <div className={className} ref='dropbox'>
        { @renderHeader() }
        <div className='Dropbox-scrollable' ref='content'>
          <div className='Dropbox-content'>
            { @props.children }
          </div>
        </div>
      </div>
    </Portal>

