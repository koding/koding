kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
formatEmojiName = require 'activity/util/formatEmojiName'
DropboxItem     = require 'activity/components/dropboxitem'
emojify         = require 'emojify.js'


module.exports = class EmojiDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  componentDidMount: -> emojify.run React.findDOMNode @refs.icon


  render: ->

    { item } = @props
    <DropboxItem {...@props} className="EmojiDropboxItem">
      <span ref='icon'>{formatEmojiName item}</span>
      {formatEmojiName item}
    </DropboxItem>

