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
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class FeedItem extends React.Component

  @defaultProps = message: immutable.Map()

  shouldComponentUpdate: (nextProps, nextState) ->
    return @props.message isnt nextProps.message

  render: ->
    { message } = @props
    <div className={kd.utils.curry 'FeedItem', @props.className}>
      <header className="FeedItem-header">
        <div className="FeedItem-headerContentWrapper">
          {makeProfileLink message.get 'account'}
          {makeTimeAgo message.get 'createdAt'}
        </div>
      </header>
      <section className="FeedItem-body">
        <div className="FeedItem-bodyContentWrapper">
          <MessageBody source={message.get 'body'} />
        </div>
      </section>
      <footer className="FeedItem-footer">
        <MessageLikeSummary className="FeedItem-likeSummary" message={message} />
      </footer>
    </div>


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
    <Avatar className="FeedItem-Avatar" width={35} height={35} />
  </ProfileLinkContainer>



