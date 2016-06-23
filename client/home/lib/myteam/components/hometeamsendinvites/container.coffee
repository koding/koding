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
      invitations: TeamFlux.getters.allInvitations
      adminInvitations: TeamFlux.getters.adminInvitations
      pendingInvitations: TeamFlux.getters.pendingInvitations
      newInvitations: TeamFlux.getters.newInvitations
      resendInvitations: TeamFlux.getters.resendInvitations
    }


  componentDidMount: ->

    canEdit = kd.singletons.groupsController.canEditGroup()
    TeamFlux.actions.updateInvitationInputValue 0, 'canEdit', yes  if canEdit


  onUploadCsv: ->
    return new kd.NotificationView
      title    : 'Coming Soon!'
      duration : 2000


  onInputChange: (index, inputName, event) ->

    value = event.target.value

    if inputName is 'canEdit'
      value = if value then yes else no

    TeamFlux.actions.updateInvitationInputValue index, inputName, value


  onSendInvites: ->

    adminInvitations = @state.adminInvitations
    resendInvitations = @state.resendInvitations
    newInvitations = @state.newInvitations
    invitations = @state.invitations
    inputValues = @state.inputValues
    ownEmail = kd.singletons.reactor.evaluate(['LoggedInUserEmailStore'])
    title = ''
    inputValues = inputValues.toArray()
    for value in inputValues
      email = value.get('email')
      break  unless email
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
    .catch ({ err }) ->
      return new kd.NotificationView
        title    : err.message
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
    content = "<p><strong>#{pendingInvitations[0].get 'email'}</strong> has already been invited. Are you sure you want to resend invitation?</p>"
    resendButtonText = 'Resend Invitation'
    cancelButtonText = 'Cancel'

    if pendingInvitations.length
      emailsText = prepareEmailsText pendingInvitations
      content = "<p>#{emailsText} have already been invited. Are you sure you want to resend invitations?</p>"
      resendButtonText = 'Resend Invitations'
      cancelButtonText = 'Just send the new ones' if invitations.size

    modal = new ResendInvitationConfirmModal
      resendButtonText : resendButtonText
      cancelButtonText : cancelButtonText
      content : content
      success : ->
        handleResendInvitations pendingInvitations, invitations
        modal.destroy()
      cancel : ->
        sendInvitations invitations
        modal.destroy()


  prepareEmailsText = (pendingInvites) ->

    len = pendingInvites.length
    emails = ''
    state = [0...len].forEach (index) ->
      email = pendingInvites[index].get('email')
      emails += "<strong>#{email}</strong>"
      if index + 2 is len
        emails += ', and '
      else if index + 1 is len
        emails += ''
      else
        emails += ', '

    return emails


  render: ->

    canEdit = kd.singletons.groupsController.canEditGroup()
    <View
      canEdit={canEdit}
      inputValues={@state.inputValues}
      onUploadCsv={@bound 'onUploadCsv'}
      onInputChange={@bound 'onInputChange'}
      onSendInvites={@bound 'onSendInvites'} />


HomeTeamSendInvitesContainer.include [KDReactorMixin]
