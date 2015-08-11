kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ActivityFlux = require 'activity/flux'
classnames   = require 'classnames'


module.exports = class DropupItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0
    className  : ''


  handleSelect: ->

    { onSelected, index } = @props
    onSelected? index


  handleClick: ->

    { onConfirmed, item } = @props
    onConfirmed? item


  render: ->

    { isSelected, className } = @props

    classesObj =
      'DropupItem'          : yes
      'DropupItem-selected' : isSelected
    classesObj[className]   = yes  if className
    classes = classnames classesObj

    <div
      className    = {classes}
      onMouseEnter = {@bound 'handleSelect'}
      onClick      = {@bound 'handleClick'}
    >
      {this.props.children}
    </div>