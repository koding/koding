kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
FeedItemAction       = require './feeditemaction'
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
          {makeLikes message.getIn ['interactions', 'like', 'actorsCount']}
          {makeComments message.get 'repliesCount'}
        </div>
        <div className="FeedItem-footerActionContainer">
          <button
            onClick={@bound 'onConversationButtonClick'}
            className="Button Button--info">View Conversation</button>
        </div>
      </footer>
    </div>


makeComments = (count) ->
  return null  unless count
  <span className="FeedItem-summaryItem FeedItem-replyCount">
    <cite>{count}</cite>
    Comments
  </span>

makeLikes = (count) ->
  return null  unless count
  <span className="FeedItem-summaryItem FeedItem-likeCount">
    <cite>{count}</cite>
    Likes
  </span>


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


makeLikeLink = (message) ->

  <MessageLikeLink message={message} />


