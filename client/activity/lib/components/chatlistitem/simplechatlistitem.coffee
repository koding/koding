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

        <ActivityPromptModal {...@getMarkUserAsTrollModalProps()} isOpen={@state.isMarkUserAsTrollModalVisible}>
          This is what we call 'Trolling the troll' mode.<br/><br/>
          All of the troll's activity will disappear from the feeds, but the troll himself will think that people still gets his posts/comments. <br/><br/>
          Are you sure you want to mark him as a troll?
        </ActivityPromptModal>

        <ActivityPromptModal {...@getBlockUserModalProps()} isOpen={@state.isBlockUserModalVisible}>
          This will block user from logging in to Koding(with all sub-groups).<br/><br/>
          You can specify a duration to block user.
          Entry format: [number][S|H|D|T|M|Y] eg. 1M<br/><br/>
          <div className="duration">
            <label className="block-user-for" for="duration">Block User For</label>
            <input name="duration" type="text" onKeyUp={@bound "onKeyUpBlockingUserTime"} ref="BlockingTimeInput" onChange={@bound "onKeyUpBlockingUserTime"} placeholder="e.g. 1Y 1W 3D 2H..."/>
          </div>
        </ActivityPromptModal>
      </div>
    </div>


