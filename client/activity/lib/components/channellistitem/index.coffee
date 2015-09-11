kd            = require 'kd'
React         = require 'kd-react'
whoami        = require 'app/util/whoami'
ActivityFlux  = require 'activity/flux'

module.exports = class PublicChannelListItem extends React.Component

  @defaultProps =
    channel  : null

  constructor: (props) ->

    super props

    @state =
      channel     : @props.channel


  unfollowChannel: (event) ->

    kd.utils.stopDOMEvent event
    { channel } = ActivityFlux.actions
    channelId = @props.channel.get '_id'

    channel.unfollowChannel channelId, whoami()._id

  render: ->
    { channel } = @props
    channelName = channel.get 'name'

    <a href="/Channels/#{channelName}" className='ChannelListItem'>
      <span className='ChannelListItem-title'>{channelName}</span>
      <button className="ChannelListItem-unfollowButton" onClick={@bound 'unfollowChannel'}>UNFOLLOW</button>
    </a>

