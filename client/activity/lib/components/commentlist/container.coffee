kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
View            = require './view'
ActivityFlux    = require 'activity/flux'

module.exports = class CommentListContainer extends React.Component

  @propTypes =
    repliesCount    : React.PropTypes.number
    channelId       : React.PropTypes.string
    messageId       : React.PropTypes.string
    onMentionClick  : React.PropTypes.func.isRequired
    comments        : React.PropTypes.instanceOf immutable.Map


  defaultProps =
    repliesCount   : 0
    channelId      : ''
    messageId      : ''
    comments       : immutable.Map()


  showMoreComment: ->

    { comments, messageId } = @props

    limit = 10
    from  = comments.first().get 'createdAt'

    ActivityFlux.actions.message.loadComments messageId, { from, limit }


  render: ->

    <View
      ref             = 'view'
      comments        = { @props.comments }
      channelId       = { @props.channelId }
      messageId       = { @props.messageId }
      repliesCount    = { @props.repliesCount }
      onMentionClick  = { @props.onMentionClick }
      showMoreComment = { @bound 'showMoreComment' }/>
