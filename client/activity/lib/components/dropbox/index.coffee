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


  componentDidUpdate: -> @calculatePosition()


  setInputDimensions: (inputDimensions) ->

    { visible, direction } = @props
    @inputDimensions = inputDimensions

    return  unless visible

    @calculatePosition()


  calculatePosition: ->

    { visible, direction } = @props
    return  unless @inputDimensions and visible

    { width, height, top, left } = @inputDimensions

    if direction is 'up'
      winHeight = $(window).height()
      css = { left, width, bottom : winHeight - top }
    else
      css = { left, width, top : top + height }

    element = $ React.findDOMNode @refs.dropbox
    element.css css


  getClassName: ->

    { className, direction } = @props

    classes =
      'Dropbox'  : yes
      'Dropdown' : direction is 'down'
      'Dropup'   : direction is 'up'
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

