kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
classnames            = require 'classnames'
formatEmojiName       = require 'activity/util/formatEmojiName'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'
emojify               = require 'emojify.js'
renderEmojiSpriteIcon = require 'activity/util/renderEmojiSpriteIcon'

module.exports = class EmojiIcon extends React.Component

  @include [ ImmutableRenderMixin ]

  @defaultProps =
    emoji : ''


  runEmojify: ->

    icon = React.findDOMNode @refs.icon
    emojify.run icon, renderEmojiSpriteIcon


  componentDidMount: -> @runEmojify()


  componentDidUpdate: -> @runEmojify()


  render: ->

    { emoji } = @props

    <span ref='icon'>
      {formatEmojiName emoji}
    </span>

