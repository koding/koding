kd                  = require 'kd'
React               = require 'kd-react'
immutable           = require 'immutable'
StartVideoCallLink  = require 'activity/components/common/startvideocalllink'
ChannelParticipants = require 'activity/components/channelparticipants'
ShareLink = require './sharelinkview'


module.exports = class CollaborationPaneHeader extends React.Component

  @propTypes =
    className                   : React.PropTypes.string
    isVideoActive               : React.PropTypes.bool
    onVideoEnd                  : React.PropTypes.func.isRequired
    onVideoStart                : React.PropTypes.func.isRequired
    thread                      : React.PropTypes.instanceOf(immutable.Map).isRequired
    participants                : React.PropTypes.instanceOf(immutable.Map).isRequired
    collaborationLink           : React.PropTypes.string.isRequired
    onNewParticipantButtonClick : React.PropTypes.func


  @defaultProps =
    className                   : ''
    isVideoActive               : no
    onNewParticipantButtonClick : null


  render: ->

    <div className={kd.utils.curry 'CollaborationPaneHeader ThreadHeader clearfix', @props.className}>
      <div className="CollaborationPaneHeader-participants">
        <ChannelParticipants.Container
          maxPreviewCount={5}
          channelThread={@props.thread}
          onNewParticipantButtonClick={@props.onNewParticipantButtonClick}
          participants={@props.participants} />
      </div>
      <div className="CollaborationPaneHeader-actions">
        <ShareLink url={@props.collaborationLink} />
        <StartVideoCallLink
          iconOnly={yes}
          isActive={@props.isVideoActive}
          onEnd={@props.onVideoEnd}
          onStart={@props.onVideoStart} />
      </div>
    </div>


