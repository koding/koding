kd    = require 'kd'
React = require 'app/react'
Button = require 'lab/Button'
SwitchTeam = require 'lab/SwitchTeam'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
styles = require './TrialEndedOptionsActions.stylus'

module.exports = TrialEndedOptionsActions = ({mainActionTitle, mainActionClick, secondaryActionClick}) ->

  <div className={styles.actions}>
    you can also <Button type='link-primary-6' size='medium' onClick={mainActionClick}>{mainActionTitle}</Button>
    <span> or </span> <Button type='link-primary-6' size='medium' onClick={secondaryActionClick}> delete your account</Button>
  </div>
