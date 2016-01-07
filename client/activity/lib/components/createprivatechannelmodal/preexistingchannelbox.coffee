React = require 'kd-react'
ProfileText = require 'app/components/profile/profiletext'


module.exports = class PreExistingChannelBox extends React.Component


  prepareParticipantText: ->

    if @props.participants.size > 1
    then text = 'these participants'
    else text = 'this participant'


  render: ->

    <div className="PreExistingChannelBox">
      <div className="PreExistingChannelBox-content">
        <p>
          You already have an existing conversation with {@prepareParticipantText()}
        </p>
      </div>
    </div>
