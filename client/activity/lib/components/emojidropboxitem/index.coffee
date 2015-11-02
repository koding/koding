kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
formatEmojiName       = require 'activity/util/formatEmojiName'
DropboxItem           = require 'activity/components/dropboxitem'
EmojiIcon             = require 'activity/components/emojiicon'


module.exports = class EmojiDropboxItem extends React.Component

  @defaultProps =
    item       : ''
    isSelected : no
    index      : 0
    query      : ''


  renderEmojiName: ->

    { item, query } = @props

    index = item.indexOf query
    if index is 0
      formatEmojiName item
    else
      <span>
        :{item.substring 0, index}
        <strong>{query}</strong>
        {item.substring index + query.length}:
      </span>


  render: ->

    { item } = @props
    <DropboxItem {...@props} className="EmojiDropboxItem">
      <EmojiIcon emoji={item} />
      {@renderEmojiName()}
    </DropboxItem>

