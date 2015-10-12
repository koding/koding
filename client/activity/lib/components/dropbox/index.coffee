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
    type      : 'dropdown'
    left      : 0


  getContentElement: -> React.findDOMNode @refs.content


  componentDidUpdate: -> kd.utils.defer @bound 'calculatePosition'


  onClose: ->

    { visible, onClose } = @props
    onClose?()  if visible


  setInputDimensions: (inputDimensions) ->

    { visible } = @props
    @inputDimensions = inputDimensions

    return  unless visible

    @calculatePosition()


  calculatePosition: ->

    { visible, type } = @props
    return  unless @inputDimensions and visible

    { width, height, top, left } = @inputDimensions

    dropbox       = React.findDOMNode @refs.dropbox
    dropboxHeight = $(dropbox).height()
    winHeight     = $(window).height()
    winWidth      = $(window).width()
    if type is 'dropup'
      type = 'dropdown'  if top - dropboxHeight < 0
    else
      type = 'dropup'  if top + height + dropboxHeight > winHeight

    css = { width, top : 'auto', bottom : 'auto' }
    if type is 'dropup'
      css.bottom = winHeight - top
    else
      css.top    = top + height

    rightDelta = @props.right
    leftDelta  = @props.left
    if rightDelta?
      css.right = winWidth - left - width - rightDelta
    else
      css.left  = left + leftDelta

    element = $ React.findDOMNode @refs.dropbox
    element
      .css css
      .toggleClass 'Dropup', type is 'dropup'
      .toggleClass 'Dropdown', type is 'dropdown'


  getClassName: ->

    { className, type } = @props

    classes =
      'Reactivity' : yes
      'Dropbox'    : yes
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
    <Portal isOpened={visible} closeOnEsc=yes closeOnOutsideClick=yes onClose={@bound 'onClose'}>
      <div className={className} ref='dropbox'>
        { @renderHeader() }
        <div className='Dropbox-scrollable' ref='content'>
          <div className='Dropbox-content'>
            { @props.children }
          </div>
        </div>
      </div>
    </Portal>

