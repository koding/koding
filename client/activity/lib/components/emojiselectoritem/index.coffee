kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
DropboxItem          = require 'activity/components/dropboxitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'

module.exports = class EmojiSelectorItem extends React.Component

  @include [ ImmutableRenderMixin ]

  @defaultProps =
    item         : immutable.Map()
    isSelected   : no
    index        : 0


  render: ->

    { item } = @props
    className = classnames
      'EmojiSelectorItem'            : yes

    <DropboxItem {...@props} className={className}>
      {formatEmojiName item}
    </DropboxItem>

