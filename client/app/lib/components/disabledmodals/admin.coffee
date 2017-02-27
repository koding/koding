kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'
{ Status } = require 'app/redux/modules/payment/constants'
globals = require 'globals'
whoami = require 'app/util/whoami'

TrialEndedAdminModal = require 'lab/TrialEndedAdminModal'
PricingChangeModal = require 'lab/PricingChangeModal'


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

    switch status

      when Status.EXPIRED, Status.NEEDS_UPGRADE
        onClick = =>
          @destroy()
          router.handleRoute '/Home/team-billing'
        <TrialEndedAdminModal
          isOpen={yes}
          onButtonClick={onClick}
          switchGroups={groups}
          owner={'owner' in globals.userRoles} />

      else
        <span />
