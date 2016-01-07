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


  renderEditMode: ->

    comment = @props.comment

    return  unless comment.get '__isEditing'

    <CommentInputWidget
      hasValue = { @state.hasValue }
      postComment={ @bound 'updateComment' }
      commentValue={ @state.commentValue }
      cancelEdit={ @bound 'cancelEdit' }
      handleCommentInputChange={ @bound 'handleCommentInputChange' } />


  renderCommentItemMenu: ->

    <MessageItemMenu
      message={@props.comment}
      disableAdminMenuItems:{yes} />


  render: ->

    { comment } = @props
    return null  unless comment

    <div className={@getClassNames()}>
      {@renderCommentItemMenu()}
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
        {@renderEditMode()}
      </div>
      <div className='CommentListItem-footer'>
        <TimeAgo from={comment.get 'createdAt'} className='CommentListItem-date' />
        {makeLike comment}
        <Link onClick={ @bound 'onClick' }>Mention</Link>
      </div>
    </div>


makeLike = (comment) ->

  return null  unless comment

  text  = 'Like'
  text  = 'Unlike'  if comment.getIn ['interactions', 'like', 'isInteracted']

  <ActivityLikeLink
    renderCount={yes}
    messageId={comment.get('id')}
    shouldSetTooltipPosition={yes}
    interactions={comment.get('interactions').toJS()}>
    {text}
  </ActivityLikeLink>
