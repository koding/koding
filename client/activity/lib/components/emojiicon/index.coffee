kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
renderEmojis         = require 'activity/util/renderEmojis'

module.exports = class EmojiIcon extends React.Component

  @include [ ImmutableRenderMixin ]

  @defaultProps =
    emoji : ''


  emojifyIcon: ->

    icon = React.findDOMNode @refs.icon
    renderEmojis icon


  componentDidMount: -> @emojifyIcon()


  componentDidUpdate: -> @emojifyIcon()


  render: ->

    { emoji } = @props

    <span ref='icon'>
      {formatEmojiName emoji}
    </span>

