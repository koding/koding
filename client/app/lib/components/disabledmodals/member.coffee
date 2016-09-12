kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'

TrialEndedMemberModal = require 'lab/TrialEndedMemberModal'
TrialEndedNotifySuccessModal = require 'lab/TrialEndedNotifySuccessModal'

module.exports = class DisabledMemberModal extends ReactView

  renderReact: ->

    { router, groupsController } = kd.singletons

    { status } = @getOptions()

    status or= getGroupStatus groupsController.getCurrentGroup()

    switch status
      when 'expired'
        onClick = =>
          @destroy()
          router.handleRoute '/Disabled/Member/notify-success'
        <TrialEndedMemberModal
          isOpen={yes}
          onButtonClick={onClick} />
      when 'notify-success'
        onClick = -> console.log 'support link clicked'
        <TrialEndedNotifySuccessModal
          isOpen={yes}
          onButtonClick={onClick} />
      else <span />


