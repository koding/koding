kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'
{ Status } = require 'app/redux/modules/payment/constants'
globals = require 'globals'
whoami = require 'app/util/whoami'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
TrialEndedAdminModal = require 'lab/TrialEndedAdminModal'
PricingChangeModal = require 'lab/PricingChangeModal'
PastDueAdminModal = require 'lab/PastDueAdminModal'
TrialEndedOptions = require 'lab/TrialEndedOptions'

module.exports = class DisabledAdminModal extends ReactView

  constructor: (options = {}, data) ->

    super options, data

    whoami().fetchRelativeGroups (err, groups) =>
      if groups.length
        @updateOptions { groups }


  renderReact: ->

    { router, groupsController } = kd.singletons

    { status, groups } = @getOptions()
    groups ?= []

    status or= getGroupStatus groupsController.getCurrentGroup()
    isOwner = 'owner' in globals.userRoles

    switch status

      when Status.EXPIRED, Status.NEEDS_UPGRADE
        onClick = =>
          @destroy()
          router.handleRoute '/Home/team-billing'
        <TrialEndedAdminModal
          isOpen={yes}
          onButtonClick={onClick}
          secondaryContent={<Options groups={groups} isOwner={isOwner} />}
        />

      when Status.PAST_DUE
        onClick = =>
          @destroy()
          router.handleRoute '/Home/team-billing'
        <PastDueAdminModal
          isOpen={yes}
          onButtonClick={onClick}
          secondaryContent={<Options groups={groups} isOwner={isOwner} />}
        />

      else
        <span />


Options = ({ isOwner, groups }) ->

  title = if isOwner then 'delete this team' else 'leave this team'
  onClick = if isOwner then deleteTeamOnClick else leaveTeamOnClick

  <TrialEndedOptions
    isOwner={isOwner}
    groups={groups}
    mainActionTitle={title}
    mainActionClick={onClick}
    secondaryActionClick={deleteAccount}
  />



leaveTeamOnClick = ->

  TeamFlux.actions.leaveTeam().catch (err) ->
    showError err


deleteTeamOnClick = ->

  TeamFlux.actions.deleteTeam().catch (err) ->
    showError err


deleteAccount = -> TeamFlux.actions.deleteAccount(subscription = no)

