kd              = require 'kd'
React           = require 'kd-react'
DropupItem      = require 'activity/components/dropupitem'

module.exports = class ChannelDropupItem extends React.Component

  render: ->

    { item } = @props
    <DropupItem {...this.props} className="ChannelDropupItem">
      <span className="ChannelDropupItem-hash"># </span>
      {item.get 'name'}
    </DropupItem>
