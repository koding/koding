kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
classnames      = require 'classnames'
formatEmojiName = require 'activity/util/formatEmojiName'
DropupItem      = require 'activity/components/dropupitem'

module.exports = class EmojiSelectorItem extends React.Component

  @defaultProps =
    item         : immutable.Map()
    isFirstInRow : no
    isSelected   : no
    index        : 0


  render: ->

    { item, isFirstInRow } = @props
    className = classnames
      'EmojiSelectorItem'            : yes
      'EmojiSelectorItem-firstInRow' : isFirstInRow

    <DropupItem {...@props} className={className}>
      {formatEmojiName item}
    </DropupItem>