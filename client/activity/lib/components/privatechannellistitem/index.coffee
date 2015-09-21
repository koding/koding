kd                    = require 'kd'
React                 = require 'kd-react'
ActivityFlux          = require 'activity/flux'
Link                  = require 'app/components/common/link'
Button                = require 'app/components/common/button'
ActivityPromptModal   = require 'app/components/activitypromptmodal'
MessageListItemHelper = require 'activity/util/messageListItemHelper'

module.exports = class PrivateChannelListItem extends React.Component

  @defaultProps =
    channel  : null

  constructor: (props) ->

    super props

    @state =
      channel     : @props.channel
      isDeleting  : no


  showDeleteChannelPromptModal: (event) ->

    kd.utils.stopDOMEvent event
    @setState isDeleting: yes


  closeDeleteChannelPromptModal: ->

    @setState isDeleting: no


  getDeleteItemModalProps: ->

    title              : "Delete message"
    body               : "Are you sure you want to delete this message?"
    buttonConfirmTitle : "DELETE"
    className          : "Modal-DeleteItemPrompt"
    onConfirm          : @bound "deleteChannelButtonHandler"
    onAbort            : @bound "closeDeleteChannelPromptModal"
    onClose            : @bound "closeDeleteChannelPromptModal"
    className          : 'PrivateChannel-deletePromptModal'
    closeIcon          : no


  deleteChannelButtonHandler: (event) ->

    kd.utils.stopDOMEvent event

    { deletePrivateChannel } = ActivityFlux.actions.channel
    channelId = @props.channel.get 'id'

    deletePrivateChannel channelId


  renderDeleteButton: ->

    if @props.channel.get('typeConstant') is 'privatemessage'
      <Button
        className="ChannelListItem-delete"
        onClick={@bound 'showDeleteChannelPromptModal'}>DELETE</Button>


  render: ->

    { channel } = @props

    typeConstant = channel.get 'typeConstant'
    title        = MessageListItemHelper.prepareThreadTitle channel
    channelName  = channel.get 'name'

    <Link href="/Channels/#{channelName}" className='ChannelListItem'>
      <span className='ChannelListItem-title'>{title}</span>
      {@renderDeleteButton()}
      <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
        Are you sure you want to delete this message?
      </ActivityPromptModal>
    </Link>

