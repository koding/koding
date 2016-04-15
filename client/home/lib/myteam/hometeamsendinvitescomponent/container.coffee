_               = require 'lodash'
kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
whoami          = require 'app/util/whoami'
showError       = require 'app/util/showError'
remote          = require('app/remote').getInstance()
AdminInviteModalView = require './admininvitemodalview'
ResendInvitationConfirmModal = require './resendinvitationconfirmmodal'


module.exports = class HomeTeamSendInvitesContainer extends React.Component

  getDataBindings: ->

    return {
      inviteInputs: TeamFlux.getters.inviteInputs
    }


  onUploadCsv: ->
    return new kd.NotificationView
      title    : 'Coming Soon!'
      duration : 2000


  onInputChange: (index, inputType, event) ->

    value = event.target.value

    if inputType is 'role'
      value = if value then 'admin' else 'member'

    TeamFlux.actions.updateInviteInput index, inputType, value


  onSendInvites: ->

    inviteInputs = @state.inviteInputs

    TeamFlux.actions.inviteMembers(inviteInputs).then ({ invites, admins }) ->

      if invites.length
        TeamFlux.actions.loadPendingInvites(invites).then ({ pendingInvitations }) ->

          if admins?.length
            notifyAdminInvites invites, admins, pendingInvitations
          else
            handleInvitationRequest invites, pendingInvitations

    .catch ({ message }) ->

      return showError message  if message


  sendInvitations = (invites, pendingInvites) ->

    TeamFlux.actions.sendInvitations(invites, pendingInvites).then ({ title }) ->
      return new kd.NotificationView
        title    : title
        duration : 5000


  handleInvitationRequest = (invites, pendingInvitations) ->

    if pendingInvitations?.size
      TeamFlux.actions.getNewInvitations(invites, pendingInvitations).then ({ newInvitations }) ->
        notifyPendingInvites pendingInvitations, { newInvitations }
    else
      sendInvitations invites


  handleResendInvitations = (pendingInvitations, newInvitations) ->

    TeamFlux.actions.resendInvitations(pendingInvitations, newInvitations).then ({ title }) ->
      return new kd.NotificationView
        title    : title
        duration : 5000

    if newInvitations.length
      sendInvitations newInvitations, pendingInvitations


  notifyAdminInvites = (invites, admins, pendingInvitations) ->

    title = if admins.length > 1 then "You're adding admins" else "You're adding an admin"
    modal = new AdminInviteModalView
      admins: admins
      title : title
      success: ->
        handleInvitationRequest invites, pendingInvitations
        modal.destroy()
      cancel: ->
        modal.destroy()


  notifyPendingInvites = (pendingInvitations, { newInvitations }) ->

    partial = "<strong>#{pendingInvitations.get(0).get 'email'}</strong> has already been invited. Are you sure you want to resend invitation?"
    resendButtonText = 'Resend Invitation'
    cancelButtonText = 'Cancel'

    if pendingInvitations.size > 1
      emailsText = prepareEmailsText pendingInvitations
      partial = "#{emailsText} have already been invited. Are you sure you want to resend invitations?"
      resendButtonText = 'Resend Invitations'
      cancelButtonText = 'Just send the new ones' if newInvitations.length

    modal = new ResendInvitationConfirmModal
      partial : partial
      resendButtonText : resendButtonText
      cancelButtonText : cancelButtonText
      success : ->
        handleResendInvitations pendingInvitations, newInvitations
        modal.destroy()
      cancel : ->
        sendInvitations newInvitations
        modal.destroy()


  prepareEmailsText = (pendingInvites) ->

    len = pendingInvites.size

    state = [0...len].reduce (state, invitation, index) ->
      email = pendingInvites.get(index).get('email')
      state += "<strong>#{email}</strong>"
      if index + 2 is len
        state += ', and '
      else if index + 1 is len
        state += ''
      else
        state += ', '
    , ''

    return state


  render: ->

    <View
      inviteInputs={@state.inviteInputs}
      onUploadCsv={@bound 'onUploadCsv'}
      onInputChange={@bound 'onInputChange'}
      onSendInvites={@bound 'onSendInvites'} />


HomeTeamSendInvitesContainer.include [KDReactorMixin]
