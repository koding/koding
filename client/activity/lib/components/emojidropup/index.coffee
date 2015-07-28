$     = require 'jquery'
kd    = require 'kd'
React = require 'kd-react'

EmojiDropupItem = require 'activity/components/emojidropupitem'

module.exports = class EmojiDropup extends React.Component

  componentDidUpdate: ->

    kd.utils.defer =>
      element = $ React.findDOMNode(this)
      element.css top : -element.outerHeight()


  renderChildren: ->

    { emojis, selectedEmoji } = @props

    emojis.map (emoji, index) ->
      isSelected = if selectedEmoji
      then emoji is selectedEmoji
      else index is 0

      <EmojiDropupItem emoji={emoji} isSelected={isSelected} />


  render: ->

    { emojis } = @props
    className = "EmojiDropup #{if emojis.size is 0 then 'hidden' else '' }"

    <div className={className}>
      {@renderChildren()}
      <div className="clearfix" />
    </div>