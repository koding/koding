kd                = require 'kd'
React             = require 'kd-react'
ActivityFlux      = require 'activity/flux'
Link              = require 'app/components/common/link'
Button            = require 'app/components/common/button'
PublicChannelLink = require 'activity/components/publicchannellink'


module.exports = class PublicChannelListItem extends React.Component

  @defaultProps =
    onItemClick : kd.noop
    thread      : null


  channel: (key) ->

    if key
    then @props.thread.getIn [ 'channel', key ]
    else @props.thread.get 'channel'


  followChannel: (event) ->

    kd.utils.stopDOMEvent event
    { channel } = ActivityFlux.actions

    channel.followChannel @channel '_id'


  unfollowChannel: (event) ->

    kd.utils.stopDOMEvent event
    { channel } = ActivityFlux.actions

    channel.unfollowChannel @channel '_id'


  renderButton: ->

    return  unless @channel('typeConstant') is 'topic'

    if @channel 'isParticipant'
      <Button
        className="ChannelListItem-unfollow"
        onClick={@bound 'unfollowChannel'}>
        LEAVE
      </Button>
    else
      <Button
        className="ChannelListItem-follow"
        onClick={@bound 'followChannel'}>
        JOIN
      </Button>


  render: ->

    channelName = @channel 'name'

    <PublicChannelLink to={@channel()} className='ChannelListItem' onClick={@props.onItemClick}>
      <span className='ChannelListItem-title'>{channelName}</span>
      {@renderButton()}
    </PublicChannelLink>

