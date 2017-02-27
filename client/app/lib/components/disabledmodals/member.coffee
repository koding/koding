kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'
{ Status } = require 'app/redux/modules/payment/constants'
globals = require 'globals'
whoami = require 'app/util/whoami'

TrialEndedMemberModal = require 'lab/TrialEndedMemberModal'
TrialEndedNotifySuccessModal = require 'lab/TrialEndedNotifySuccessModal'

SuspendedMemberModal = require 'lab/SuspendedMemberModal'
SuspendedNotifySuccessModal = require 'lab/SuspendedNotifySuccessModal'


module.exports = class DisabledMemberModal extends ReactView

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

    onLogoutClick = =>
      @destroy()
      router.handleRoute '/Logout'

    switch status

      when Status.EXPIRED, Status.NEEDS_UPGRADE
        onClick = =>
          @destroy()
          router.handleRoute '/Disabled/Member/notify-success'
        <TrialEndedMemberModal
          isOpen={yes}
          onButtonClick={onClick}
          switchGroups={groups}
          owner={'owner' in globals.userRoles} />

      when Status.PAST_DUE, Status.CANCELED
        onClick = =>
          @destroy()
          router.handleRoute '/Disabled/Member/suspended-notify-success'
        <SuspendedMemberModal
          isOpen={yes}
          onButtonClick={onClick}
          onSecondaryButtonClick={onLogoutClick} />

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

      else
        <span />
