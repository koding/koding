kd            = require 'kd'
React         = require 'kd-react'
ActivityFlux  = require 'activity/flux'
Link          = require 'app/components/common/link'
Button        = require 'app/components/common/button'

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
      <Button
        className="ChannelListItem-unfollow"
        onClick={@bound 'unfollowChannel'}>
        UNFOLLOW
      </Button>
    else
      <Button
        className="ChannelListItem-follow"
        onClick={@bound 'followChannel'}>
        FOLLOW
      </Button>


  render: ->

    { channel } = @props
    channelName = channel.get 'name'

    <Link href="/Channels/#{channelName}" className='ChannelListItem'>
      <span className='ChannelListItem-title'>{channelName}</span>
      {@renderButton()}
    </Link>

