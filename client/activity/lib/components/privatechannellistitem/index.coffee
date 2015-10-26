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


  channel: (key) ->

    if key
    then @props.thread.getIn [ 'channel', key ]
    else @props.thread.get 'channel'


  render: ->

    typeConstant = @channel 'typeConstant'
    title        = prepareThreadTitle @props.thread
    channelId    = @channel '_id'

    <PrivateChannelLink to={@channel()} className='ChannelListItem' onClick={@props.onItemClick}>
      <span className='ChannelListItem-title'>{title}</span>
    </PrivateChannelLink>

