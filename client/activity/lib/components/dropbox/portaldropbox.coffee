$       = require 'jquery'
kd      = require 'kd'
React   = require 'kd-react'
Portal  = require 'react-portal'
Dropbox = require './index'

module.exports = class PortalDropbox extends React.Component

  @defaultProps =
    left : 0


  componentDidUpdate: -> kd.utils.defer @bound 'calculatePosition'


  getContentElement: -> @refs.dropbox.getContentElement()


  setInputDimensions: (inputDimensions) ->

    { visible } = @props
    @inputDimensions = inputDimensions

    return  unless visible

    @calculatePosition()


  calculatePosition: ->

    { visible, type } = @props
    return  unless @inputDimensions and visible

    { width, height, top, left } = @inputDimensions

    dropbox       = $ React.findDOMNode @refs.dropbox
    dropboxHeight = dropbox.height()
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

    dropbox
      .css css
      .toggleClass 'Dropup', type is 'dropup'
      .toggleClass 'Dropdown', type is 'dropdown'


  render: ->

    { visible } = @props

    <Portal isOpened={visible} className='PortalDropbox'>
      <Dropbox {...@props} ref='dropbox'>
        { @props.children }
      </Dropbox>
    </Portal>

