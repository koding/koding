kd              = require 'kd'
React           = require 'kd-react'
formatEmojiName = require 'activity/util/formatEmojiName'
DropupItem      = require 'activity/components/dropupitem'

module.exports = class EmojiDropupItem extends React.Component

  render: ->

    { item } = @props
    <DropupItem {...this.props} className="EmojiDropupItem">
      {formatEmojiName item}
    </DropupItem>
