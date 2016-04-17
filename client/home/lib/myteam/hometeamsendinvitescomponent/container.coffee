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
isEmailValid = require 'app/util/isEmailValid'


module.exports = class HomeTeamSendInvitesContainer extends React.Component

  getDataBindings: ->

    return {
      inputValues: TeamFlux.getters.invitationInputValues
      invitations: TeamFlux.getters.invitations
      adminInvitations: TeamFlux.getters.adminInvitations
      pendingInvitations: TeamFlux.getters.pendingInvitations
      newInvitations: TeamFlux.getters.newInvitations
      resendInvitations: TeamFlux.getters.resendInvitations
    }


  onUploadCsv: ->
    return new kd.NotificationView
      title    : 'Coming Soon!'
      duration : 2000


  onInputChange: (index, inputName, event) ->

    value = event.target.value

    if inputName is 'role'
      value = if value then 'admin' else 'member'

    TeamFlux.actions.updateInvitationInputValue index, inputName, value


  onSendInvites: ->

    adminInvitations = @state.adminInvitations
    resendInvitations = @state.resendInvitations
    newInvitations = @state.newInvitations
    invitations = @state.invitations
    inputValues = @state.inputValues
    ownEmail = kd.singletons.reactor.evaluate(['LoggedInUserEmailStore'])
    title=''
    inputValues = inputValues.toArray()
    for value in inputValues
      email = value.get('email')

      if email is ownEmail
        title = 'You can not invite yourself!'
        break
      else unless isEmailValid email
        title = 'That doesn\'t seem like a valid email address.'
        break

    if title isnt ''
      return new kd.NotificationView
          title    : title
          duration : 5000

    if adminInvitations.size
      notifyAdminInvites newInvitations, adminInvitations, resendInvitations
    else
      handleInvitationRequest newInvitations, resendInvitations


  sendInvitations = (invitations) ->

    return  unless invitations.size
    TeamFlux.actions.sendInvitations().then ({ title }) ->
      return new kd.NotificationView
        title    : title
        duration : 5000
    .catch ({ title }) ->
      return new kd.NotificationView
        title    : title
        duration : 5000


  handleInvitationRequest = (invitations, resendInvitations) =>

    if resendInvitations?.size
      notifyPendingInvites resendInvitations, invitations
    else
      sendInvitations invitations


  handleResendInvitations = (invitations) ->

    TeamFlux.actions.resendInvitations().then ({ title }) ->
      new kd.NotificationView
        title    : title
        duration : 5000
    .catch ({ title }) ->
      new kd.NotificationView
          title    : title
          duration : 5000


  notifyAdminInvites = (invitations, admins, resendInvitations) ->

    admins = admins
      .map (admin) ->
        admin.get 'email'
      .toArray()

    title = if admins.size > 1 then "You're adding admins" else "You're adding an admin"
    modal = new AdminInviteModalView
      admins: admins
      title : title
      success: ->
        handleInvitationRequest invitations, resendInvitations
        modal.destroy()
      cancel: ->
        modal.destroy()


  notifyPendingInvites = (pendingInvitations, invitations) ->
    pendingInvitations = pendingInvitations.toArray()
    partial = "<strong>#{pendingInvitations[0].get 'email'}</strong> has already been invited. Are you sure you want to resend invitation?"
    resendButtonText = 'Resend Invitation'
    cancelButtonText = 'Cancel'

    if pendingInvitations.size > 1
      emailsText = prepareEmailsText pendingInvitations
      partial = "#{emailsText} have already been invited. Are you sure you want to resend invitations?"
      resendButtonText = 'Resend Invitations'
      cancelButtonText = 'Just send the new ones' if invitations.size

    modal = new ResendInvitationConfirmModal
      partial : partial
      resendButtonText : resendButtonText
      cancelButtonText : cancelButtonText
      success : ->
        handleResendInvitations pendingInvitations, invitations
        modal.destroy()
      cancel : ->
        sendInvitations invitations
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
      inputValues={@state.inputValues}
      onUploadCsv={@bound 'onUploadCsv'}
      onInputChange={@bound 'onInputChange'}
      onSendInvites={@bound 'onSendInvites'} />


HomeTeamSendInvitesContainer.include [KDReactorMixin]
