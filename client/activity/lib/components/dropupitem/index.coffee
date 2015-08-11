kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ActivityFlux = require 'activity/flux'
classnames   = require 'classnames'
Link         = require 'app/components/common/link'


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

    linkClasses =
      'DropupItem'          : yes
      'DropupItem-selected' : isSelected
    linkClasses[className]  = yes  if className
    linkClassName = classnames linkClasses

    <Link
      className    = {linkClassName}
      onMouseEnter = {@bound 'handleSelect'}
      onClick      = {@bound 'handleClick'}
    >
      <span className='DropupItem-itemName'>{this.props.children}</span>
    </Link>