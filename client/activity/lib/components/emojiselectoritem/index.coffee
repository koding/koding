kd              = require 'kd'
React           = require 'kd-react'
ActivityFlux    = require 'activity/flux'
classnames      = require 'classnames'
formatEmojiName = require 'activity/util/formatEmojiName'

module.exports = class EmojiSelectorItem extends React.Component

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