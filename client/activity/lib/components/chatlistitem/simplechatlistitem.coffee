kd                   = require 'kd'
React                = require 'kd-react'
MessageBody          = require 'activity/components/common/messagebody'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ChatListItem         = require 'activity/components/chatlistitem'
MessageTime          = require 'activity/components/chatlistitem/messagetime'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
MarkUserAsTrollModal = require 'app/components/markuserastrollmodal'
BlockUserModal       = require 'app/components/blockusermodal'
ActivityPromptModal  = require 'app/components/activitypromptmodal'
classnames           = require 'classnames'
MessageLink          = require 'activity/components/messagelink'


module.exports = class SimpleChatListItem extends ChatListItem


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
          {@renderEmbedBox()}
        </div>
        {@renderEditMode()}
        {@renderChatItemMenu()}
        <div className='clearfix'></div>
        <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
          Are you sure you want to delete this post?
        </ActivityPromptModal>
        <MarkUserAsTrollModal {...@getMarkUserAsTrollModalProps()} isOpen={@state.isMarkUserAsTrollModalVisible} />
        <BlockUserModal {...@getBlockUserModalProps()} isOpen={@state.isBlockUserModalVisible} />
      </div>
    </div>


