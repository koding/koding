kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
formatEmojiName = require 'activity/util/formatEmojiName'
DropupItem      = require 'activity/components/dropupitem'

module.exports = class EmojiDropupItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item } = @props
    <DropupItem {...@props} className="EmojiDropupItem">
      {formatEmojiName item}
    </DropupItem>
