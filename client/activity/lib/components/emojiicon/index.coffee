kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
renderEmojis         = require 'activity/util/renderEmojis'

module.exports = class EmojiIcon extends React.Component

  @include [ ImmutableRenderMixin ]

  @defaultProps =
    emoji       : ''
    showTooltip : yes


  emojifyIcon: ->

    icon = ReactDOM.findDOMNode @refs.icon
    renderEmojis icon, @props.showTooltip


  componentDidMount: -> @emojifyIcon()


  componentDidUpdate: -> @emojifyIcon()


  render: ->

    { emoji } = @props

    <span ref='icon'>
      {formatEmojiName emoji}
    </span>

