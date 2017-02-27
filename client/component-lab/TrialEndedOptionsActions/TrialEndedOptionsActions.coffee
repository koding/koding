kd    = require 'kd'
React = require 'app/react'
Button = require 'lab/Button'
SwitchTeam = require 'lab/SwitchTeam'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
styles = require './TrialEndedOptionsActions.stylus'

module.exports = TrialEndedOptionsActions = ({mainActionTitle, mainActionClick, secondaryActionClick}) ->

  <div>
    <div className={styles.mainaction}>
      <Button type='primary-6' size='medium' onClick={mainActionClick}>{mainActionTitle}</Button>
    </div>
    <div className={styles.secondaryaction}>
      <Button type='link-primary-6' size='medium' onClick={secondaryActionClick}>Or Delete Your Account</Button>
    </div>
  </div>
