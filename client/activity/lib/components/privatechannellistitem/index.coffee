kd                    = require 'kd'
React                 = require 'kd-react'
ActivityFlux          = require 'activity/flux'
ActivityPromptModal   = require 'app/components/activitypromptmodal'

module.exports = class PrivateChannelListItem extends React.Component

  @defaultProps =
    channel  : null

  constructor: (props) ->

    super props

    @state =
      channel     : @props.channel
      isDeleting  : no


  showDeletePostPromptModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isDeleting: yes


  closeDeletePostModal: ->

    @setState isDeleting: no


  getDeleteItemModalProps: ->

    title              : "Delete post"
    body               : "Are you sure you want to delete this post?"
    buttonConfirmTitle : "DELETE"
    className          : "Modal-DeleteItemPrompt"
    onConfirm          : @bound "deletePostButtonHandler"
    onAbort            : @bound "closeDeletePostModal"
    onClose            : @bound "closeDeletePostModal"
    className          : 'PrivateChannel-deletePromptModal'
    closeIcon          : no


  deletePostButtonHandler: (event) ->

    kd.utils.stopDOMEvent event

    { deletePrivateChannel } = ActivityFlux.actions.channel
    channelId = @props.channel.get 'id'

    deletePrivateChannel channelId


  renderDeleteButton: ->

    if @props.channel.get('typeConstant') is 'privatemessage'
      <button
        className="ChannelListItem-delete button"
        onClick={@bound 'showDeletePostPromptModal'}>DELETE</button>


  render: ->

    { channel } = @props

    typeConstant = channel.get 'typeConstant'
    title        = if typeConstant is 'bot' then 'Bot Koding' else channel.get 'purpose'
    channelName  = channel.get 'name'

    <a href="/Channels/#{channelName}" className='ChannelListItem'>
      <span className='ChannelListItem-title'>{title}</span>
      {@renderDeleteButton()}
      <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
        Are you sure you want to delete this message?
      </ActivityPromptModal>
    </a>

