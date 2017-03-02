React = require 'app/react'
SwitchTeam = require 'lab/SwitchTeam'
TrialEndedOptionsActions = require 'lab/TrialEndedOptionsActions'


module.exports = TrialEndedOptions = ({groups, isOwner, mainActionTitle, mainActionClick, secondaryActionClick}) ->

  <div>
    {groups?.length and <SwitchTeam groups={groups} isOwner={isOwner} />}
    <TrialEndedOptionsActions
      mainActionTitle={mainActionTitle}
      mainActionClick={mainActionClick}
      secondaryActionClick={secondaryActionClick} />
  </div>
