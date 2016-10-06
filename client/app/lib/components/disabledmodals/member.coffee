kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'
{ Status } = require 'app/redux/modules/payment/constants'

TrialEndedMemberModal = require 'lab/TrialEndedMemberModal'
TrialEndedNotifySuccessModal = require 'lab/TrialEndedNotifySuccessModal'

UpgradeNeededMemberModal = require 'lab/UpgradeNeededMemberModal'
UpgradeNeededNotifySuccessModal = require 'lab/UpgradeNeededNotifySuccessModal'

SuspendedMemberModal = require 'lab/SuspendedMemberModal'
SuspendedNotifySuccessModal = require 'lab/SuspendedNotifySuccessModal'

module.exports = class DisabledMemberModal extends ReactView

  renderReact: ->

    { router, groupsController } = kd.singletons

    { status } = @getOptions()

    status or= getGroupStatus groupsController.getCurrentGroup()

    switch status

      when Status.EXPIRED
        onClick = =>
          @destroy()
          router.handleRoute '/Disabled/Member/notify-success'
        <TrialEndedMemberModal
          isOpen={yes}
          onButtonClick={onClick} />

      when Status.PAST_DUE, Status.CANCELED
        onClick = =>
          @destroy()
          router.handleRoute '/Disabled/Member/suspended-notify-success'
        <SuspendedMemberModal
          isOpen={yes}
          onButtonClick={onClick} />

      when Status.NEEDS_UPGRADE
        onClick = =>
          @destroy()
          router.handleRoute '/Disabled/Member/upgrade-notify-success'
        <UpgradeNeededMemberModal
          isOpen={yes}
          onButtonClick={onClick} />

      when 'suspended-notify-success'
        onClick = -> console.log 'support link clicked'
        <SuspendedNotifySuccessModal
          isOpen={yes}
          onButtonClick={onClick} />

      when 'notify-success'
        onClick = -> console.log 'support link clicked'
        <TrialEndedNotifySuccessModal
          isOpen={yes}
          onButtonClick={onClick} />

      when 'upgrade-notify-success'
        onClick = -> console.log 'support link clicked'
        <UpgradeNeededNotifySuccessModal
          isOpen={yes}
          onButtonClick={onClick} />

      else
        <span />

