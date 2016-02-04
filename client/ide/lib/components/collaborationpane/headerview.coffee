kd                  = require 'kd'
React               = require 'kd-react'
immutable           = require 'immutable'
StartVideoCallLink  = require 'activity/components/common/startvideocalllink'
ChannelParticipants = require 'activity/components/channelparticipants'
ShareLink = require './sharelinkview'


module.exports = class CollaborationPaneHeader extends React.Component

  @propTypes =
    className     : React.PropTypes.string
    isVideoActive : React.PropTypes.bool
    onVideoEnd    : React.PropTypes.func.isRequired
    onVideoStart  : React.PropTypes.func.isRequired
    thread        : React.PropTypes.instanceOf(immutable.Map).isRequired
    participants  : React.PropTypes.instanceOf(immutable.Map).isRequired
    collaborationLink : React.PropTypes.string


  @defaultProps =
    className     : ''
    isVideoActive : no
    collaborationLink: 'https://team.koding.com/Collaboration/umut/1234124871284'


  render: ->

    <div className={kd.utils.curry 'CollaborationPaneHeader ThreadHeader', @props.className}>
      <div className="CollaborationPaneHeader-participants">
        <ChannelParticipants.Container
          maxPreviewCount={5}
          channelThread={@props.thread}
          onNewParticipantButtonClick={@props.onNewParticipantButtonClick}
          participants={@props.participants} />
      </div>
      <ShareLink url={@props.collaborationLink} />
      <StartVideoCallLink
        isActive={@props.isVideoActive}
        onEnd={@props.onVideoEnd}
        onStart={@props.onVideoStart} />
    </div>



