kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
FeedItemAction       = require './feeditemaction'
MessageLikeSummary   = require 'activity/components/common/messagelikesummary'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class FeedItem extends React.Component

  @defaultProps = message: immutable.Map()

  shouldComponentUpdate: (nextProps, nextState) ->
    return @props.message isnt nextProps.message

  render: ->
    { message } = @props
    <div className={kd.utils.curry 'FeedItem', @props.className}>
      <header className="FeedItem-header">
        <div className="FeedItem-headerContentWrapper MediaObject">
          <div className="MediaObject-media">
            {makeAvatar message.get 'account'}
          </div>
          <div className="MediaObject-content">
            <div className="FeedItem-headerTopRow">
              <span>{makeProfileLink message.get 'account'}</span>
            </div>
            <div className="FeedItem-headerBottomRow">
              <span>{makeTimeAgo message.get 'createdAt'}</span>
            </div>
          </div>
        </div>
      </header>
      <section className="FeedItem-body">
        <div className="FeedItem-bodyContentWrapper">
          <MessageBody source={message.get 'body'} />
        </div>
        <div className="FeedItem-actionsContainer">
          <FeedItemAction>Like</FeedItemAction>
          <FeedItemAction>Comment</FeedItemAction>
          <FeedItemAction>Share</FeedItemAction>
        </div>
      </section>
      <footer className="FeedItem-footer">
        <MessageLikeSummary className="FeedItem-likeSummary" message={message} />
      </footer>
    </div>


makeTimeAgo = (createdAt) ->
  <a href="#" className="FeedItem-date">
    <TimeAgo from={createdAt} />
  </a>

makeProfileLink = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <ProfileText />
  </ProfileLinkContainer>

makeAvatar = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <Avatar className="FeedItem-Avatar" width={35} height={35} />
  </ProfileLinkContainer>



