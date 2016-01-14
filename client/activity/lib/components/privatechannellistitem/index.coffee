kd                 = require 'kd'
React              = require 'kd-react'
immutable          = require 'immutable'
prepareThreadTitle = require 'activity/util/prepareThreadTitle'
PrivateChannelLink = require 'activity/components/privatechannellink'

module.exports = class PrivateChannelListItem extends React.Component

  @propTypes =
    thread      : React.PropTypes.instanceOf immutable.Map
    onItemClick : React.PropTypes.func.isRequired


  @defaultProps =
    thread      : immutable.Map()


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
