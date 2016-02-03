kd                  = require 'kd'
React               = require 'kd-react'
immutable           = require 'immutable'
StartVideoCallLink  = require 'activity/components/common/startvideocalllink'
ChannelParticipants = require 'activity/components/channelparticipants'
Link                = require 'app/components/common/link'


module.exports = class CollaborationPaneHeader extends React.Component

  @propTypes =
    className     : React.PropTypes.string
    isVideoActive : React.PropTypes.bool
    onVideoEnd    : React.PropTypes.func.isRequired
    onVideoStart  : React.PropTypes.func.isRequired
    thread        : React.PropTypes.instanceOf(immutable.Map).isRequired
    participants  : React.PropTypes.instanceOf(immutable.Map).isRequired


  @defaultProps =
    className     : ''
    isVideoActive : no


  render: ->

    <div className={kd.utils.curry 'ThreadHeader', @props.className}>
      <ChannelParticipants.Container
        channelThread={@props.thread}
        participants={@props.participants} />
      <StartVideoCallLink
        isActive={@props.isVideoActive}
        onEnd={@props.onVideoEnd}
        onStart={@props.onVideoStart} />
    </div>


ParticipantsSection = ({thread, participants}) ->


