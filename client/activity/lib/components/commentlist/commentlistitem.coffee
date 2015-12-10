kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageLink          = require 'activity/components/messagelink'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'

module.exports = class CommentListItem extends React.Component

  defaultProps=
    comment        : immutable.Map()
    onMentionClick : kd.noop


  onClick: (event) ->

    kd.utils.stopDOMEvent event

    { onMentionClick, comment } = @props

    onMentionClick comment


  render: ->

    { comment } = @props
    return null  unless comment

    <div className='CommentListItem'>
      <div className='MediaObject-media'>
        <ProfileLinkContainer origin={comment.get('account').toJS()}>
          <Avatar className='FeedItem-Avatar' width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <ProfileLinkContainer key={comment.getIn(['account', 'id'])} origin={comment.get('account').toJS()}>
        <ProfileText />
      </ProfileLinkContainer>
      <div className='CommentListItem-body'>
        {comment.get 'body'}
      </div>
      <div className='CommentListItem-footer'>
        <TimeAgo from={comment.get 'createdAt'} className='CommentListItem-date' />
        <ActivityLikeLink
          tooltip={no}
          messageId={comment.get('id')}
          interactions={comment.get('interactions').toJS()}>
          Like
          <span className='CommentListItem-likeCount'>
            {comment.getIn ['interactions', 'like', 'actorsCount']}
          </span>
        </ActivityLikeLink>
        <Link onClick={ @bound 'onClick' }>Mention</Link>
      </div>
    </div>

