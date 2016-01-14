kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
ChannelLabel = require 'activity/components/channellabel'
Button       = require 'app/components/common/button'

module.exports = class FeedThreadHeader extends React.Component

  @propTypes =
    className : React.PropTypes.string
    channel   : React.PropTypes.instanceOf immutable.Map()


  @defaultProps =
    className : ''
    channel   : immutable.Map()


  onClick: ->

    channelId     = @props.channel.get 'id'
    isParticipant = @props.channel.get 'isParticipant'

    if isParticipant
      ActivityFlux.actions.channel.unfollowChannel channelId
    else
      ActivityFlux.actions.channel.followChannel channelId


  getFollowButtonClassNames: -> classnames
    'FeedList-followButton' : yes
    'following'             : @props.channel.get 'isParticipant'


  render: ->

    return null  unless @props.channel

    <div className={kd.utils.curry "ThreadHeader", @props.className}>
      <ChannelLabel channel={@props.channel} />
      <Button
        className={@getFollowButtonClassNames()}}
        onClick={@bound 'onClick'}>
      </Button>
    </div>
