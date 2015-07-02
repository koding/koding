kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class ChatListItem extends React.Component

  getItemProps: ->
    key       : @props.message.get 'id'
    className : kd.utils.curry 'ChatItem', @props.className

  render: ->
    { message } = @props
    <div {...@getItemProps()}>
      <div className="ChatItem-contentWrapper MediaObject">
        <div className="MediaObject-media">
          {makeAvatar message.get 'account'}
        </div>
        <div className="MediaObject-content">
          <div className="ChatItem-contentHeader">
            <span className="ChatItem-authorName">
              {makeProfileLink message.get 'account'}
            </span>
            <span className="ChatItem-messageDate">
              {makeTimeAgo message.get 'createdAt'}
            </span>
          </div>
          <div className="ChatItem-contentBody">
            <MessageBody source={message.get 'body'} />
          </div>
        </div>
      </div>
    </div>


makeTimeAgo = (createdAt) ->
  <a href="#" className="TopicChatItem-date">
    <TimeAgo from={createdAt} />
  </a>

makeProfileLink = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <ProfileText />
  </ProfileLinkContainer>

makeAvatar = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <Avatar className="ChatItem-Avatar" width={35} height={35} />
  </ProfileLinkContainer>


