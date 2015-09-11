kd                    = require 'kd'
React                 = require 'kd-react'

module.exports = class PublicChannelListItem extends React.Component

  @defaultProps =
    channel  : null


  unfollowChannel: ->

    console.log 'unfollowChannel clicked'


  constructor: (props) ->

    super props

    @state =
      channel     : @props.channel


  render: ->
    { channel } = @props
    channelName = channel.get 'name'

    <a href="/Channels/#{channelName}" className='ChannelListItem'>
      <span className='ChannelListItem-title'>{channelName}</span>
      <button className="ChannelListItem-unfollowButton" onClick={@bound 'unfollowChannel'}>UNFOLLOW</button>
    </a>

