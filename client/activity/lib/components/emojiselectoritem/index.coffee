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
    isFirstInRow : no
    isSelected   : no
    index        : 0


  render: ->

    { item, isFirstInRow } = @props
    className = classnames
      'EmojiSelectorItem'            : yes
      'EmojiSelectorItem-firstInRow' : isFirstInRow

    <DropboxItem {...@props} className={className}>
      {formatEmojiName item}
    </DropboxItem>

