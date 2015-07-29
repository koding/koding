kd           = require 'kd'
React        = require 'kd-react'
ActivityFlux = require 'activity/flux'
classnames   = require 'classnames'


module.exports = class EmojiDropupItem extends React.Component

  handleSelect: ->

    { index } = @props
    ActivityFlux.actions.emoji.selectEmoji index


  handleClick: (event) ->

    event.preventDefault()
    ActivityFlux.actions.emoji.clearEmojiQuery()


  render: ->

    { emoji, isSelected } = @props
    className = classnames
      'EmojiDropupItem'         : yes
      'EmojiDropupItem-selected': isSelected

    <a
      href         = "#"
      className    = {className}
      onMouseEnter = {@bound 'handleSelect'}
      onClick      = {@bound 'handleClick'}
    >
      <span className="EmojiDropupItem-emojiName">:{emoji}:</span>
    </a>