React = require 'kd-react'
ProfileText = require 'app/components/profile/profiletext'


module.exports = class PreExistingChannelBox extends React.Component


  prepareParticipants: ->

    @props.participants.toList().toJS()
      .map (participant) -> <ProfileText account={participant} />


  render: ->

    <div className="PreExistingChannelBox">
      <div className="PreExistingChannelBox-content">
        <p>
          You already have an existing conversation with {@prepareParticipants()}
        </p>
      </div>
    </div>

