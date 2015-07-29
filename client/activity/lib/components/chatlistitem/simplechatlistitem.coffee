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

  getClassNames: ->
    edit: classnames
      'ChatItem-updateMessageForm': yes
      'hidden': not @state.editMode
    media: classnames
      'MediaObject-content': yes
      'hidden': @state.editMode
    content: classnames
      'ChatItem-contentWrapper MediaObject SimpleChatListItem': yes
      'editing': @state.editMode


  render: ->

    { message } = @props
    <div {...@getItemProps()}>
      <div className={@getClassNames().content}>
        <div className={@getClassNames().media}>
          <MessageTime date={message.get 'createdAt'}/>
          <ActivityLikeLink />
          <div className="ChatItem-contentBody">
            <MessageBody source={message.get 'body'} />
          </div>
        </div>
        <div className={@getClassNames().edit}>
          <textarea onKeyDown = { @bound 'handleEditMessageKeyDown' } defaultValue={ message.get 'body' } ref="EditMessageTextarea"></textarea>
          <button className="solid green done-button" type="button" onClick={@bound 'updateMessage'} >DONE</button>
          <button className="cancel-editing" type="button" onClick={@bound 'cancelEdit'} >CANCEL</button>
        </div>
        <ButtonWithMenu items={@getMenuItems()} showMenuForMouseAction={@state.showMenuForMouseAction}/>
      </div>
    </div>


