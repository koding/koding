kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
classnames           = require 'classnames'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
MessageItemMenu      = require 'activity/components/messageitemmenu'
CommentInputWidget   = require 'activity/components/commentinputwidget'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class CommentListItemView extends React.Component

  @propTypes =
    hasValue      : React.PropTypes.bool
    commentValue  : React.PropTypes.string
    updateComment : React.PropTypes.func.isRequired
    cancelEdit    : React.PropTypes.func.isRequired
    onClick       : React.PropTypes.func.isRequired
    onChange      : React.PropTypes.func.isRequired
    comment       : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    hasValue      : no
    commentValue  : ''
    comment       : immutable.Map()


  getClassNames: ->

    { comment } = @props

    classnames
      'CommentListItem' : yes
      'editing'         : comment.get '__isEditing'
      'edited'          : comment.get('createdAt') isnt comment.get('updatedAt')


  renderEditMode: ->

    comment = @props.comment

    return  unless comment.get '__isEditing'

    <CommentInputWidget.Container
      ref          = 'CommentInputWidget'
      hasValue     = { @props.hasValue }
      postComment  = { @props.updateComment }
      commentValue = { @props.commentValue }
      cancelEdit   = { @props.cancelEdit }
      isEditing    = { comment.get '__isEditing' }
      onChange     = { @props.onChange } />


  renderCommentItemMenu: ->

    <MessageItemMenu
      disableAdminMenuItems = { yes }
      message               = { @props.comment } />


  render: ->

    { comment } = @props

    return null  unless comment

    <div className={@getClassNames()}>
      {@renderCommentItemMenu()}
      <div className='MediaObject-media'>
        <ProfileLinkContainer origin={comment.get('account').toJS()}>
          <Avatar width={35} height={35} />
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
        <Link ref='MentionLink' onClick={ @props.onClick }>Mention</Link>
      </div>
    </div>


makeLike = (comment) ->

  return null  unless comment

  text  = 'Like'
  text  = 'Unlike'  if comment.getIn ['interactions', 'like', 'isInteracted']

  <ActivityLikeLink
    renderCount              = { yes }
    shouldSetTooltipPosition = { yes }
    messageId                = { comment.get('id') }
    interactions             = { comment.get('interactions').toJS() } >
    { text }
  </ActivityLikeLink>
