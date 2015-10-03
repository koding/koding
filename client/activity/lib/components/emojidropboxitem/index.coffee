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
    query      : ''


  componentDidMount: -> emojify.run React.findDOMNode @refs.icon


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
      <span ref='icon'>{formatEmojiName item}</span>
      {@renderEmojiName()}
    </DropboxItem>

