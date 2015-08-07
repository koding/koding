kd              = require 'kd'
React           = require 'kd-react'
ActivityFlux    = require 'activity/flux'
classnames      = require 'classnames'
formatEmojiName = require 'activity/util/formatEmojiName'
Link            = require 'app/components/common/link'


module.exports = class EmojiDropupItem extends React.Component

  handleSelect: ->

    { onSelect, index } = @props
    onSelect? index


  handleClick: -> @props.onClick?()


  render: ->

    { emoji, isSelected } = @props
    className = classnames
      'EmojiDropupItem'         : yes
      'EmojiDropupItem-selected': isSelected

    <Link
      className    = {className}
      onMouseEnter = {@bound 'handleSelect'}
      onClick      = {@bound 'handleClick'}
    >
      <span className="EmojiDropupItem-emojiName">{formatEmojiName emoji}</span>
    </Link>