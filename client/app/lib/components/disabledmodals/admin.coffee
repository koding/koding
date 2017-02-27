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
          secondaryContent={
            <TrialEndedOptions
              isOwner={isOwner}
              groups={groups}
              mainActionTitle={if isOwner then 'DELETE THIS TEAM' else 'LEAVE THIS TEAM'}
              mainActionClick={if isOwner then deleteTeamOnClick else leaveTeamOnClick}
              secondaryActionClick={deleteAccount} />}
          />

      else
        <span />


leaveTeamOnClick = ->

  TeamFlux.actions.leaveTeam().catch (err) ->
    showError err


deleteTeamOnClick = ->

  TeamFlux.actions.deleteTeam().catch (err) ->
    showError err


deleteAccount = -> TeamFlux.actions.deleteAccount()

