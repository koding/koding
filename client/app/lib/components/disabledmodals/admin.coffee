kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
getGroupStatus = require 'app/util/getGroupStatus'

TrialEndedAdminModal = require 'lab/TrialEndedAdminModal'

module.exports = class DisabledAdminModal extends ReactView

  renderReact: ->

    { router, groupsController } = kd.singletons

    { status } = @getOptions()

    status or= getGroupStatus groupsController.getCurrentGroup()

    switch status
      when 'expired'
        onClick = =>
          @destroy()
          router.handleRoute '/Home/team-billing'
        <TrialEndedAdminModal
          isOpen={yes}
          onButtonClick={onClick} />
      else <span />


