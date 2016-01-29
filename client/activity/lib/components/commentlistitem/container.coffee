kd           = require 'kd'
View         = require './view'
React        = require 'kd-react'
immutable    = require 'immutable'
ActivityFlux = require 'activity/flux'

module.exports = class CommentListItemContainer extends React.Component

  @propTypes =
    channelId      : React.PropTypes.string
    onMentionClick : React.PropTypes.func.isRequired
    comment        : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    channelId      : ''
    comment        : immutable.Map()


  constructor: (props) ->

    super

    @state =
      hasValue     : yes
      commentValue : @props.comment.get('body') or ''
      focusOnInput : no


  onClick: (event) ->

    kd.utils.stopDOMEvent event

    { onMentionClick, comment } = @props

    onMentionClick comment


  updateComment: ->

    commentId = @props.comment.get '_id'
    { message } = ActivityFlux.actions

    message.unsetMessageEditMode commentId, @props.channelId
    message.editMessage commentId, @state.commentValue.trim()


  cancelEdit: ->

    { comment, channelId } = @props
    { message } = ActivityFlux.actions

    @setState { commentValue: comment.get 'body' }

    message.unsetMessageEditMode comment.get('_id'), channelId


  onChange: (event) ->

    hasValue = no
    value    = event.target.value
    hasValue = yes  if value.trim()
    @setState { hasValue, commentValue: value }


  render: ->

    <View
      ref           = 'view'
      comment       = { @props.comment }
      hasValue      = { @state.hasValue }
      onClick       = { @bound 'onClick' }
      onChange      = { @bound 'onChange' }
      cancelEdit    = { @bound 'cancelEdit' }
      commentValue  = { @state.commentValue }
      updateComment = { @bound 'updateComment' } />

