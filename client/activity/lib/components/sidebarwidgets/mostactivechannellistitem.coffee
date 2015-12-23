kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Link         = require 'app/components/common/link'
Button       = require 'app/components/common/button'

module.exports = class MostActiveChannelListItem extends React.Component

  @defaultProps=
    channel = immutable.Map()

  getFollowButtonClassNames: -> classnames
    'FeedList-followButton'  : yes
    'following': @props.channel.get 'isParticipant'


  onClick: (event) ->

    kd.utils.stopDOMEvent event

    { followChannel, unfollowChannel } = ActivityFlux.actions.channel

    channelId     = @props.channel.get 'id'
    isParticipant = @props.channel.get 'isParticipant'

    if isParticipant
      unfollowChannel channelId
    else
      followChannel channelId


  render: ->

    href="/Channels/#{@props.channel.get 'name'}"

    <Link href={href} className='MostActiveChannelItem'>
      <span>{@props.channel.get 'name'}</span>
      <Button
        className={@getFollowButtonClassNames()}}
        onClick={@bound 'onClick'}>
      </Button>
    </Link>


