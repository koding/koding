kd                    = require 'kd'
React                 = require 'kd-react'
ActivityFlux          = require 'activity/flux'
Button                = require 'app/components/common/button'
prepareThreadTitle    = require 'activity/util/prepareThreadTitle'
PrivateChannelLink    = require 'activity/components/privatechannellink'

module.exports = class PrivateChannelListItem extends React.Component

  @defaultProps =
    onItemClick : kd.noop
    thread      : null

  constructor: (props) ->

    super props

    @state = { isDeleting  : no }


  channel: (key) ->

    if key
    then @props.thread.getIn [ 'channel', key ]
    else @props.thread.get 'channel'


  showDeleteConfirmButtons: ->

    @setState isDeleting: yes


  cancelDeleting: ->

    @setState isDeleting: no


  confirmDelete: (event) ->

    kd.utils.stopDOMEvent event

    channelId = @channel 'id'
    { deletePrivateChannel } = ActivityFlux.actions.channel

    deletePrivateChannel channelId


  renderDeleteChannelConfirmButtons: ->

    return null  unless @state.isDeleting

    return \
      <div>
        <Button
          className="ChannelListItem-button confirm"
          onClick={@bound 'confirmDelete'}>Confirm</Button>
        <Button
          className="ChannelListItem-button cancel"
          onClick={@bound 'cancelDeleting'}>Cancel</Button>
      </div>


  renderDeleteButton: ->

    if @channel('typeConstant') is 'privatemessage' and not @state.isDeleting
      <Button
        className="ChannelListItem-delete"
        onClick={@bound 'showDeleteConfirmButtons'}>DELETE</Button>


  render: ->

    typeConstant = @channel 'typeConstant'
    title        = prepareThreadTitle @props.thread
    channelId    = @channel '_id'

    <PrivateChannelLink to={@channel()} className='ChannelListItem' onClick={@props.onItemClick}>
      <span className='ChannelListItem-title'>{title}</span>
      {@renderDeleteButton()}
      {@renderDeleteChannelConfirmButtons()}
    </PrivateChannelLink>

