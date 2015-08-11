kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
classnames      = require 'classnames'
formatEmojiName = require 'activity/util/formatEmojiName'

module.exports = class EmojiSelectorItem extends React.Component

  @defaultProps =
    emoji        : immutable.Map()
    isFirstInRow : no
    isSelected   : no
    index        : 0


  handleSelect: ->

    { onSelect, index } = @props
    onSelect? index


  handleClick: -> @props.onClick?()


  render: ->

    { emoji, isFirstInRow, isSelected } = @props
    className = classnames
      'EmojiSelectorItem'            : yes
      'EmojiSelectorItem-firstInRow' : isFirstInRow
      'EmojiSelectorItem-selected'   : isSelected

    <div
      className    = { className }
      onMouseEnter = { @bound 'handleSelect'}
      onClick      = { @bound 'handleClick' }>
        {formatEmojiName emoji}
    </div>