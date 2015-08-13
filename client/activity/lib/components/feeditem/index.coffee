kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
MessageLikeSummary   = require 'activity/components/common/messagelikesummary'
Avatar               = require 'app/components/profile/avatar'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
MessageLikeLink      = require 'activity/components/common/messagelikelink'


module.exports = class FeedItem extends React.Component

  @defaultProps = message: immutable.Map()

  shouldComponentUpdate: (nextProps, nextState) ->
    return @props.message isnt nextProps.message

  onConversationButtonClick: (event) ->

    kd.utils.stopDOMEvent event

    kd.singletons.router.handleRoute "/Channels/Public/summary/#{@props.message.get 'slug'}"

  render: ->
    { message } = @props
    <div className={kd.utils.curry 'FeedItem', @props.className}>
      <header className="FeedItem-header">
        <div className="FeedItem-headerContentWrapper">
          {makeProfileLink message.get 'account'}
          {makeTimeAgo message.get 'createdAt'}
          {makeLikeLink message}
        </div>
      </header>
      <section className="FeedItem-body">
        <div className="FeedItem-bodyContentWrapper">
          <MessageBody source={message.get 'body'} />
        </div>
      </section>
      <footer className="FeedItem-footer">
        <div className="FeedItem-summary">
          {makeAvatarGroup message}
        </div>
        <div className="FeedItem-footerActionContainer">
          <button
            onClick={@bound 'onConversationButtonClick'}
            className="Button Button--info">View Conversation</button>
          {makeRepliesCount message}
        </div>
      </footer>
    </div>


makeAvatarGroup = (message) ->
  return null  unless message.get('replies').size
  avatars = message.get('replies')
    .reduce (people, reply) ->
      people.set reply.getIn(['account', '_id']), reply.get 'account'
    , immutable.Map()
    .map makeAvatar

  return (
    <span className="FeedItem-avatarGroup">
      <span className="FeedItem-avatarGroupLabel">People:</span>
      {avatars}
    </span>
  )

makeTimeAgo = (createdAt) ->
  <Link className="FeedItem-date u-color-light-text">
    <TimeAgo from={createdAt} />
  </Link>

makeProfileLink = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <ProfileText />
  </ProfileLinkContainer>

makeAvatar = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <Avatar className="FeedItem-Avatar" width={28} height={28} />
  </ProfileLinkContainer>


makeLikeLink = (message) -> <MessageLikeLink message={message} />


makeRepliesCount = (message) ->
  repliesCount = message.get 'repliesCount'
  label = if repliesCount is 1 then 'reply' else 'replies'

  <span className="FeedItem-repliesCount">
    <span className="FeedItem-repliesCountNumber">{repliesCount}</span>
    <span className="FeedItem-repliesCountLable">{label}</span>
  </span>

