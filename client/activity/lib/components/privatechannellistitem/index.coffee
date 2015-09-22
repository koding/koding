kd                    = require 'kd'
React                 = require 'kd-react'
ActivityFlux          = require 'activity/flux'
Link                  = require 'app/components/common/link'
Button                = require 'app/components/common/button'
ActivityPromptModal   = require 'app/components/activitypromptmodal'
prepareThreadTitle    = require 'activity/util/prepareThreadTitle'
PrivateChannelLink    = require 'activity/components/privatechannellink'

module.exports = class PrivateChannelListItem extends React.Component

  @defaultProps =
    channel     : null
    onItemClick : kd.noop
    thread      : null

  constructor: (props) ->

    super props

    @state =
      channel     : @props.channel
      isDeleting  : no


  channel: (key) ->

    if key
    then @props.thread.getIn [ 'channel', key ]
    else @props.thread.get 'channel'


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
    channelId = @channel 'id'

    deletePrivateChannel channelId


  renderDeleteButton: ->

    if @channel('typeConstant') is 'privatemessage'
      <Button
        className="ChannelListItem-delete"
        onClick={@bound 'showDeleteChannelPromptModal'}>DELETE</Button>


  render: ->

    typeConstant = @channel 'typeConstant'
    title        = prepareThreadTitle @props.thread
    channelId    = @channel '_id'

    <PrivateChannelLink to={@channel()} className='ChannelListItem' onClick={@props.onItemClick}>
      <span className='ChannelListItem-title'>{title}</span>
      {@renderDeleteButton()}
      <ActivityPromptModal {...@getDeleteItemModalProps()} isOpen={@state.isDeleting}>
        Are you sure you want to delete this message?
      </ActivityPromptModal>
    </PrivateChannelLink>

