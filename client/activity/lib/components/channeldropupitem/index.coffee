kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
DropupItem = require 'activity/components/dropupitem'

module.exports = class ChannelDropupItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item } = @props
    <DropupItem {...@props} className="ChannelDropupItem">
      <span className="ChannelDropupItem-hash"># </span>
      {item.get 'name'}
    </DropupItem>
