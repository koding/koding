kd              = require 'kd'
View            = require './view'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'


module.exports = class FeedThreadHeaderContainer extends React.Component

  @propTypes =
    channel   : React.PropTypes.instanceOf immutable.Map
    className : React.PropTypes.string


  @defaultProps =
    channel   : immutable.Map()
    className : ''


  onClick: ->

    channelId     = @props.channel.get 'id'
    isParticipant = @props.channel.get 'isParticipant'

    if isParticipant
      ActivityFlux.actions.channel.unfollowChannel channelId
    else
      ActivityFlux.actions.channel.followChannel channelId

  render: ->

    <View
      channel   = { @props.channel }
      onClick   = { @bound 'onClick' }
      className = { @props.className } />
