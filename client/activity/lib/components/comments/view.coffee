kd                 = require 'kd'
React              = require 'kd-react'
classnames         = require 'classnames'
immutable          = require 'immutable'
CommentList        = require './commentlist'
CommentInputWidget = require './commentinputwidget'

module.exports = class CommentsView extends React.Component

  @propTypes =
    hasValue       : React.PropTypes.bool
    repliesCount   : React.PropTypes.number
    commentValue   : React.PropTypes.string
    messageId      : React.PropTypes.string
    channelId      : React.PropTypes.string
    postComment    : React.PropTypes.func.isRequired
    onChange       : React.PropTypes.func.isRequired
    onMentionClick : React.PropTypes.func.isRequired
    comments       : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    repliesCount   : 0
    hasValue       : no
    channelId      : ''
    messageId      : ''
    commentValue   : ''
    comments       : immutable.Map()


  render: ->

    <div className='CommentsWrapper'>
      <CommentList
        ref            = 'CommentList'
        comments       = { @props.comments }
        channelId      = { @props.channelId }
        onMentionClick = { @props.onMentionClick }
        messageId      = { @props.messageId }
        repliesCount   = { @props.repliesCount }/>
      <CommentInputWidget
        ref          = 'CommentInputWidget'
        hasValue     = { @props.hasValue }
        onChange     = { @props.onChange }
        postComment  = { @props.postComment }
        commentValue = { @props.commentValue }/>
    </div>
