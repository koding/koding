kd    = require 'kd'
React = require 'kd-react'
ActivityFlux   = require 'activity/flux'

module.exports = class EmojiDropupItem extends React.Component

  handleSelect: ->

    { emoji } = @props
    ActivityFlux.actions.emoji.selectEmoji emoji


  render: ->

    { emoji, isSelected } = @props
    className = "EmojiDropupItem #{if isSelected then 'EmojiDropupItem-selected' else ''}"

    <a href="#" className={className} onMouseEnter={@bound 'handleSelect'}>
      <span className="EmojiDropupItem-emojiName">:{emoji}:</span>
    </a>