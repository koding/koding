kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
Encoder              = require 'htmlencode'
immutable            = require 'immutable'
classnames           = require 'classnames'
MessageLink          = require 'activity/components/messagelink'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
MessageItemMenu      = require 'activity/components/messageitemmenu'
ActivityFlux         = require 'activity/flux'
CommentInputWidget   = require './commentinputwidget'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class CommentListItem extends React.Component

  @defaultProps =
    channelId      : null
    comment        : immutable.Map()
    onMentionClick : kd.noop

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

    message.unsetMessageEditMode comment.get '_id', channelId


  handleCommentInputChange: (event) ->

    hasValue = no
    value    = event.target.value
    hasValue = yes  if value.trim()
    @setState { hasValue: hasValue, commentValue: value }


  getClassNames: ->

    { comment } = @props

    classnames
      'CommentListItem' : yes
      'editing'         : comment.get '__isEditing'
      'edited'          : comment.get('createdAt') isnt comment.get('updatedAt')


  render: ->

    { comment } = @props
    return null  unless comment

    <div className={@getClassNames()}>
      <div className='MediaObject-media'>
        <ProfileLinkContainer origin={comment.get('account').toJS()}>
          <Avatar className='FeedItem-Avatar' width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <ProfileLinkContainer key={comment.getIn(['account', 'id'])} origin={comment.get('account').toJS()}>
        <ProfileText />
      </ProfileLinkContainer>
      <div className='CommentListItem-body'>
        <MessageBody message={comment} />
      </div>
      <div className='CommentListItem-footer'>
        <TimeAgo from={comment.get 'createdAt'} className='CommentListItem-date' />
        <ActivityLikeLink
          tooltip={no}
          messageId={comment.get('id')}
          interactions={comment.get('interactions').toJS()}>
          Like
          {makeLike comment.getIn ['interactions', 'like', 'actorsCount']}
        </ActivityLikeLink>
        <Link onClick={ @bound 'onClick' }>Mention</Link>
      </div>
    </div>


makeLike = (count) ->

  return null  unless count

  <span className='CommentListItem-likeCount'>{count}</span>

