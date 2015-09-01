kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
formatEmojiName = require 'activity/util/formatEmojiName'
DropupItem      = require 'activity/components/dropupitem'
emojify         = require 'emojify.js'


module.exports = class EmojiDropupItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  componentDidMount: -> emojify.run React.findDOMNode this.refs.icon


  render: ->

    { item } = @props
    <DropupItem {...@props} className="EmojiDropupItem">
      <span ref='icon'>{formatEmojiName item}</span>
      {formatEmojiName item}
    </DropupItem>

