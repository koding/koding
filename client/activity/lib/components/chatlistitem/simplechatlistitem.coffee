kd                   = require 'kd'
React                = require 'kd-react'
TimeAgo              = require 'app/components/common/timeago'
MessageBody          = require 'activity/components/common/messagebody'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ChatListItem         = require 'activity/components/chatlistitem'
MessageTime          = require 'activity/components/chatlistitem/messagetime'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
ActivityPromptModal  = require 'app/components/activitypromptmodal'
classnames           = require 'classnames'


module.exports = class SimpleChatListItem extends ChatListItem


  getContentClassNames: -> classnames
    'ChatItem-contentWrapper MediaObject SimpleChatListItem': yes
    'editing': @state.editMode
    'edited' : @isEditedMessage()


  render: ->

    { message } = @props
    <div {...@getItemProps()}>
      <div className={@getContentClassNames()}>
        <div className={@getMediaObjectClassNames()}>
          <MessageTime date={message.get 'createdAt'}/>
          <ActivityLikeLink messageId={message.get('id')} interactions={message.get('interactions').toJS()}/>
          <div className="ChatItem-contentBody">
            <MessageBody source={message.get 'body'} />
          </div>
        </div>
        {@renderEditMode()}
        {@renderChatItemMenu()}
        <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
          Are you sure you want to delete this post?
        </ActivityPromptModal>
      </div>
    </div>


