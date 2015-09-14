kd            = require 'kd'
React         = require 'kd-react'
ActivityFlux  = require 'activity/flux'

module.exports = class PublicChannelListItem extends React.Component

  @defaultProps =
    channel  : null

  constructor: (props) ->

    super props

    @state =
      channel     : @props.channel


  followChannel: (event) ->

    kd.utils.stopDOMEvent event
    { channel } = ActivityFlux.actions
    channelId = @props.channel.get '_id'

    channel.followChannel channelId


  unfollowChannel: (event) ->

    kd.utils.stopDOMEvent event
    { channel } = ActivityFlux.actions
    channelId = @props.channel.get '_id'

    channel.unfollowChannel channelId


  renderButton: ->

    { channel } = @props

    return  unless channel.get('typeConstant') is 'topic'

    if channel.get 'isParticipant'
      <button className="ChannelListItem-unfollow button" onClick={@bound 'unfollowChannel'}>UNFOLLOW</button>
    else
      <button className="ChannelListItem-follow button" onClick={@bound 'followChannel'}>FOLLOW</button>


  render: ->

    { channel } = @props
    channelName = channel.get 'name'

    <a href="/Channels/#{channelName}" className='ChannelListItem'>
      <span className='ChannelListItem-title'>{channelName}</span>
      {@renderButton()}
    </a>

