kd                   = require 'kd'
React                = require 'kd-react'
TimeAgo              = require 'app/components/common/timeago'
MessageBody          = require 'activity/components/common/messagebody'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ChatListItem         = require 'activity/components/chatlistitem'
MessageTime          = require 'activity/components/chatlistitem/messagetime'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
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
        <div className={@getEditModeClassNames()}>
          <textarea onKeyDown = { @bound 'handleEditMessageKeyDown' } defaultValue={ message.get 'body' } ref="EditMessageTextarea"></textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'} >DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
        <ButtonWithMenu items={@getMenuItems()} showMenuForMouseAction={@state.showMenuForMouseAction}/>
      </div>
    </div>


