kd                   = require 'kd'
React                = require 'kd-react'
DropboxItem          = require 'activity/components/dropboxitem'
EmojiIcon            = require 'activity/components/emojiicon'
ImmutableRenderMixin = require 'react-immutable-render-mixin'

module.exports = class EmojiSelectorItem extends React.Component

  @include [ ImmutableRenderMixin ]

  @defaultProps =
    item         : ''
    isSelected   : no
    index        : 0


  render: ->

    { item } = @props

    <DropboxItem {...@props} className='EmojiSelectorItem'>
      <EmojiIcon emoji={item} />
    </DropboxItem>

