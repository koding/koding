$       = require 'jquery'
kd      = require 'kd'
React   = require 'kd-react'
Portal  = require 'react-portal'
Dropbox = require './dropboxbody'

module.exports = class PortalDropbox extends React.Component

  MIN_HEIGHT = 100

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
    scrollable    = dropbox.find '.Dropbox-scrollable'

    # reset scrollable height before calculations
    # to have initial dropbox height
    scrollable.css { height : 'auto' }

    scrollHeight  = scrollable.height()
    dropboxHeight = dropbox.height()
    winHeight     = $(window).height()
    winWidth      = $(window).width()

    # check if dropbox is too close to window border
    # and therefore type should be changed to reverse
    if type is 'dropup'
      type = 'dropdown'  if top < MIN_HEIGHT
    else
      type = 'dropup'  if top + height + MIN_HEIGHT > winHeight

    # calculate vertical coordinates of dropbox
    # and height delta if it doesn't fit the window height
    css = { width, top : 'auto', bottom : 'auto' }
    if type is 'dropup'
      css.bottom  = winHeight - top
      heightDelta = dropboxHeight - top
    else
      css.top     = top + height
      heightDelta = css.top + dropboxHeight - winHeight

    # calculate horizontal coordinates
    rightDelta = @props.right
    leftDelta  = @props.left
    if rightDelta?
      css.right = winWidth - left - width - rightDelta
    else
      css.left  = left + leftDelta

    # update dropbox position and css class depending on the type
    dropbox
      .css css
      .toggleClass 'Dropup', type is 'dropup'
      .toggleClass 'Dropdown', type is 'dropdown'

    # update scrollable container height
    # if dropbox doesn't fit the window height
    scrollHeight = if heightDelta > 0 then scrollHeight - heightDelta else 'auto'
    scrollable.css { height : scrollHeight }


  render: ->

    { visible } = @props

    <Portal isOpened={visible} className='PortalDropbox'>
      <Dropbox {...@props} ref='dropbox'>
        { @props.children }
      </Dropbox>
    </Portal>

