kd                   = require 'kd'
React                = require 'kd-react'
TimeAgo              = require 'app/components/common/timeago'
MessageBody          = require 'activity/components/common/messagebody'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ChatListItem         = require 'activity/components/chatlistitem'
MessageTime          = require 'activity/components/chatlistitem/messagetime'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'

module.exports = class ConsequentMessageItem extends ChatListItem

  render: ->

    { message } = @props
    editFormClass       = if @state.editMode then 'ChatItem-updateMessageForm' else 'ChatItem-updateMessageForm hidden'
    mediaContentClass   = if @state.editMode then 'MediaObject-content hidden' else 'MediaObject-content'
    contentWrapperClass = if @state.editMode then 'ChatItem-contentWrapper MediaObject ConsequentMessageItem editing' else 'ChatItem-contentWrapper MediaObject ConsequentMessageItem'
    <div {...@getItemProps()}>
      <div className={contentWrapperClass}>
        <div className={mediaContentClass}>
          <MessageTime date={message.get 'createdAt'}/>
          <ActivityLikeLink />
          <div className="ChatItem-contentBody">
            <MessageBody source={message.get 'body'} />
          </div>
        </div>
        <div className={editFormClass}>
          <textarea onKeyDown = { @bound 'handleEditMessageKeyDown' } defaultValue={ message.get 'body' } ref="EditMessageTextarea"></textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'} >DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
        <ButtonWithMenu items={@getMenuItems()} showMenuForMouseAction={@state.showMenuForMouseAction}/>
      </div>
    </div>
