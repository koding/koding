kd    = require 'kd'
React = require 'app/react'
Button = require 'lab/Button'
SwitchTeam = require 'lab/SwitchTeam'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
styles = require './TrialEndedOptions.stylus'

module.exports = TrialEndedOptions = ({groups, owner}) ->

  <div>
    {renderSwitchTeam groups, owner}
    {renderMainAction owner}
    {renderSecondaryAction()}
  </div>


renderSwitchTeam = (groups, owner) ->

  return  unless groups.length

  <SwitchTeam groups={groups} owner={owner} />


renderMainAction = (owner) ->

  buttonTitle = if owner then 'DELETE THIS TEAM' else 'LEAVE THIS TEAM'
  buttonOnClick = if owner then deleteTeamOnClick else leaveTeamOnClick

  <div className={styles.mainaction}>
    <Button type='primary-6' size='medium' onClick={buttonOnClick}>{buttonTitle}</Button>
  </div>


renderSecondaryAction = ->

  <div className={styles.secondaryaction}>
    <Button type='link-primary-6' size='medium' onClick={deleteAccount}>Or Delete Your Account</Button>
  </div>


leaveTeamOnClick = ->

  modalContent = '
  <p>
    <strong>CAUTION! </strong>You are going to leave your team and you will not be able to login again.
    This action <strong>CANNOT</strong> be undone.
  </p> <br>
  <p>Please enter your <strong>current password</strong> into the field below to continue: </p>
  '

  TeamFlux.actions.leaveTeam(modalContent).catch (err) ->
    showError err


deleteTeamOnClick = ->

  modalContent = '
  <p>
    <strong>CAUTION! </strong>You are going to delete your team. You and your
    team members will not be able to access this team again.
    This action <strong>CANNOT</strong> be undone.
  </p> <br>
  <p>Please enter your <strong>current password</strong> into the field below to continue: </p>'

  TeamFlux.actions.deleteTeam(modalContent).catch (err) ->
    showError err


deleteAccount = -> TeamFlux.actions.deleteAccount()
