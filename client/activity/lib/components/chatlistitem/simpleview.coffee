kd               = require 'kd'
React            = require 'kd-react'
MessageBody      = require 'activity/components/common/messagebody'
ChatListItemView = require 'activity/components/chatlistitem/view'
MessageTime      = require 'activity/components/chatlistitem/messagetime'
classnames       = require 'classnames'
MessageLink      = require 'activity/components/messagelink'
ActivityLikeLink = require 'activity/components/chatlistitem/activitylikelink'

module.exports = class SimpleChatListItemView extends ChatListItemView

  getContentClassNames: -> classnames
    'ChatItem-contentWrapper MediaObject SimpleChatListItem': yes
    'editing': @props.message.get '__isEditing'
    'edited' : @isEditedMessage()


  render: ->

    { message } = @props
    <div {...@getItemProps()}>
      <div className={@getContentClassNames()}>
        <div className={@getMediaObjectClassNames()}>
          <MessageLink message={message}>
            <MessageTime className='ChatItem-messageDate' date={message.get 'createdAt'}/>
          </MessageLink>
          <ActivityLikeLink messageId={message.get('id')} interactions={message.get('interactions').toJS()}/>
          <div className="ChatItem-contentBody">
            <MessageBody message={message} />
          </div>
        </div>
        {@renderEditMode()}
        {@renderEmbedBox()}
        {@renderChatItemMenu()}
        <div className='clearfix'></div>
      </div>
    </div>
