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

    PREVIEW_COUNT = @getPreviewCount()

    participants.slice(0, PREVIEW_COUNT).toList().map (participant) ->
      <div key={participant.get 'id'} className="ChannelParticipantAvatars-singleBox">
        <ProfileLinkContainer account={participant.toJS()}>
          <Avatar
            className="ChannelParticipantAvatars-avatar"
            width={30}
            account={participant.toJS()}
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
  getNewParticipantInputClassNames: -> classnames
    'ChannelParticipantInput': yes
    'slide-down': @state.addNewParticipantMode


  renderAddNewParticipantInput: ->

    <div className={@getNewParticipantInputClassNames()}>
      <input placeholder="type a @username and hit enter" />
    </div>


  render: ->
    <div className="ChannelParticipantAvatars">
      {@renderAvatars()}
      {@renderMoreCount()}
      {@renderNewParticipantButton()}
      {@renderAddNewParticipantInput()}
    </div>

