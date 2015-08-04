kd                   = require 'kd'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
immutable            = require 'immutable'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'


module.exports = class ChannelParticipantAvatars extends React.Component

  MAX_PREVIEW_COUNT = 4

  @defaultProps =
    channelThread : null
    participants  : null


  renderAvatars: ->
    return null  unless @props.participants

    { participants } = @props

    count = if participants.size is MAX_PREVIEW_COUNT + 1
    then MAX_PREVIEW_COUNT + 1
    else MAX_PREVIEW_COUNT

    participants.slice(0, count).toList().map (participant) ->
      <div key={participant.get 'id'} className="ChannelParticipantAvatars-singleBox">
        <ProfileLinkContainer account={participant.toJS()}>
          <Avatar
            className="ChannelParticipantAvatars-avatar"
            width={30}
            height={30} />
        </ProfileLinkContainer>
      </div>


  renderMoreCount: ->
    return null  unless @props.participants

    moreCount = @props.participants.size - MAX_PREVIEW_COUNT
    return null  unless moreCount > 1

    moreCount = Math.min moreCount, 99

    <div className="ChannelParticipantAvatars-singleBox">
      <div className="ChannelParticipantAvatars-moreCount">
        {moreCount}+
      </div>
    </div>


  renderNewParticipantButton: -> null


  render: ->
    <div className="ChannelParticipantAvatars">
      {@renderAvatars()}
      {@renderMoreCount()}
      {@renderNewParticipantButton()}
    </div>
