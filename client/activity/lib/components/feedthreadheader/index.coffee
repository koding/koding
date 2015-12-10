kd                   = require 'kd'
React                = require 'kd-react'
classnames           = require 'classnames'
ActivityFlux         = require 'activity/flux'
ChannelLabel         = require 'activity/components/channellabel'
Button               = require 'app/components/common/button'

module.exports = class FeedThreadHeader extends React.Component

  @defaultProps =
    thread                     : null

  onClick: ->

    channelId     = @props.thread.getIn ['channel', 'id']
    isParticipant = @props.thread.getIn ['channel', 'isParticipant']

    if isParticipant
      ActivityFlux.actions.channel.unfollowChannel channelId
    else
      ActivityFlux.actions.channel.followChannel channelId


  getFollowButtonClassNames: -> classnames
    'FeedList-followButton'  : yes
    'following': @props.thread.getIn ['channel', 'isParticipant']


  render: ->

    return null  unless @props.thread

    <div className={kd.utils.curry "ThreadHeader", @props.className}>
      <ChannelLabel thread={@props.thread} />
      <Button
        className={@getFollowButtonClassNames()}}
        onClick={@bound 'onClick'}>
      </Button>
    </div>


