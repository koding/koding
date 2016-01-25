kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
immutable            = require 'immutable'
ActivityFlux         = require 'activity/flux'
View                 = require './view'
SimpleView           = require './simpleview'
ImmutableRenderMixin = require 'react-immutable-render-mixin'

module.exports = class ChatListItemContainer extends React.Component

  @include [ImmutableRenderMixin]

  @propTypes =
    channelName  : React.PropTypes.string
    showItemMenu : React.PropTypes.bool
    isSelected   : React.PropTypes.bool
    channelId    : React.PropTypes.string
    isSimple     : React.PropTypes.bool

  @defaultProps =
    channelName  : ''
    showItemMenu : yes
    isSelected   : no
    channelId    : ''
    isSimple     : no


  onSubmit: (value) ->

    messageId = @props.message.get '_id'

    ActivityFlux.actions.message.unsetMessageEditMode messageId, @props.channelId
    ActivityFlux.actions.message.editMessage messageId, value


  onCancelEdit: ->

    messageId = @props.message.get '_id'
    ActivityFlux.actions.message.unsetMessageEditMode messageId, @props.channelId, yes


  onCloseEmbedBox: ->

    ActivityFlux.actions.message.disableEditedEmbedPayload @props.message.get('id')


  render: ->

    { isSimple } = @props
    Component    = if isSimple then SimpleView else View

    <Component {...@props}
      onSubmit        = { @bound 'onSubmit' }
      onCancelEdit    = { @bound 'onCancelEdit' }
      onCloseEmbedBox = { @bound 'onCloseEmbedBox' }
    />
