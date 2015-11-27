kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ActivityFlux = require 'activity/flux'
classnames   = require 'classnames'


module.exports = class DropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0
    className  : ''


  handleSelect: ->

    { onSelected, index } = @props
    onSelected? index


  handleLeave: ->

    { onUnselected, index } = @props
    onUnselected? index


  handleClick: ->

    { onConfirmed, item } = @props
    onConfirmed? item


  getClassName: ->

    { isSelected, className } = @props

    classes =
      'DropboxItem'          : yes
      'DropboxItem-selected' : isSelected
    classes[className]       = yes  if className

    return classnames classes


  render: ->

    className = @getClassName()

    <div
      className    = {className}
      onMouseEnter = {@bound 'handleSelect'}
      onClick      = {@bound 'handleClick'}
      onMouseLeave = {@bound 'handleLeave'}
    >
      {@props.children}
    </div>

