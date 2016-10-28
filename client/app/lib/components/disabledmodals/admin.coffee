kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'
{ Status } = require 'app/redux/modules/payment/constants'

TrialEndedAdminModal = require 'lab/TrialEndedAdminModal'
PricingChangeModal = require 'lab/PricingChangeModal'

module.exports = class DisabledAdminModal extends ReactView

  renderReact: ->

    { router, groupsController } = kd.singletons

    { status } = @getOptions()

    status or= getGroupStatus groupsController.getCurrentGroup()

    switch status

      when Status.EXPIRED
        onClick = =>
          @destroy()
          router.handleRoute '/Home/team-billing'
        <TrialEndedAdminModal
          isOpen={yes}
          onButtonClick={onClick} />

      when Status.NEEDS_UPGRADE
        onClick = -> location.reload()
        <PricingChangeModal
          isOpen={yes}
          onButtonClick={onClick} />

      else
        <span />


