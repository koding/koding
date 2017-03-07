React = require 'app/react'
SwitchTeam = require 'lab/SwitchTeam'
TrialEndedOptionsActions = require 'lab/TrialEndedOptionsActions'


module.exports = TrialEndedOptions = ({groups, isOwner, mainActionTitle, mainActionClick, secondaryActionClick}) ->

  <div>
    {<SwitchTeam groups={groups} isOwner={isOwner} />  if groups.length}
    <TrialEndedOptionsActions
      mainActionTitle={mainActionTitle}
      mainActionClick={mainActionClick}
      secondaryActionClick={secondaryActionClick} />
  </div>
