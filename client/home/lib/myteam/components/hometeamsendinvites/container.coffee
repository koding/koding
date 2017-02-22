_ = require 'lodash'
$ = require 'jquery'
kd = require 'kd'
React = require 'app/react'
TeamFlux = require 'app/flux/teams'
KDReactorMixin = require 'app/flux/base/reactormixin'
View = require './view'
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
remote = require 'app/remote'
AdminInviteModalView = require './admininvitemodalview'
ResendInvitationConfirmModal = require './resendinvitationconfirmmodal'
AlreadyMemberInvitationsModal = require './alreadymemberinvitationmodal'
isEmailValid = require 'app/util/isEmailValid'
UploadCSVModal = require './uploadcsvmodal'
UploadCSVModalSuccess = require './uploadcsvsuccessmodal'
{ actions : HomeActions } = require 'home/flux'


module.exports = class HomeTeamSendInvitesContainer extends React.Component

  getDataBindings: ->

    return {
      inputValues: TeamFlux.getters.invitationInputValues
      invitations: TeamFlux.getters.allInvitations
      adminInvitations: TeamFlux.getters.adminInvitations
      pendingInvitations: TeamFlux.getters.pendingInvitations
      newInvitations: TeamFlux.getters.newInvitations
      resendInvitations: TeamFlux.getters.resendInvitations
      alreadyMemberInvitations: TeamFlux.getters.alreadyMemberInvitations
    }


  componentDidMount: ->

    canEdit = kd.singletons.groupsController.canEditGroup()
    TeamFlux.actions.updateInvitationInputValue 0, 'canEdit', yes  if canEdit


  onUploadCSV: (event) ->

    modal = new UploadCSVModal
      success : @bound 'uploadCSVSuccess'
      error : @bound 'uploadCSVFail'


  uploadCSVSuccess: (result) ->

    new UploadCSVModalSuccess
      totalInvitation: result
    TeamFlux.actions.loadPendingInvitations()


  uploadCSVFail: ->
    new kd.NotificationView
      title : 'Error Occured while handling invitations'
      duration : 5000

  onInputChange: (index, inputName, event) ->

    value = event.target.value

    if inputName is 'canEdit'
      value = if value then yes else no

    TeamFlux.actions.updateInvitationInputValue index, inputName, value

  onInputEmailBlur: (index, event) ->

    { value, classList } = event.target

    classList.toggle("error", !isEmailValid value)  if value

  onSendInvites: ->

    adminInvitations = @state.adminInvitations
    resendInvitations = @state.resendInvitations
    newInvitations = @state.newInvitations
    invitations = @state.invitations
    inputValues = @state.inputValues
    alreadyMemberInvitations = @state.alreadyMemberInvitations
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
      notifyAdminInvites newInvitations, adminInvitations, resendInvitations, alreadyMemberInvitations
    else if alreadyMemberInvitations.size
      notifyAlreadyMemberInvitations newInvitations, resendInvitations, alreadyMemberInvitations
    else
      handleInvitationRequest newInvitations, resendInvitations


  sendInvitations = (invitations) ->

    return  unless invitations.size
    TeamFlux.actions.sendInvitations().then ({ title }) ->
      HomeActions.markAsDone 'inviteTeam'
      return new kd.NotificationView
        title    : title
        duration : 5000
    .catch ({ err }) ->
      return new kd.NotificationView
        title    : err.message
        duration : 5000


  handleInvitationRequest = (invitations, resendInvitations) ->

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


  notifyAdminInvites = (invitations, admins, resendInvitations, alreadyMemberInvitations) ->

    admins = admins
      .map (admin) ->
        admin.get 'email'
      .toArray()

    title = if admins.size > 1 then "You're adding admins" else "You're adding an admin"
    modal = new AdminInviteModalView
      admins: admins
      title : title
      success: ->
        if alreadyMemberInvitations.size
          notifyAlreadyMemberInvitations invitations, resendInvitations, alreadyMemberInvitations
        else
          handleInvitationRequest invitations, resendInvitations
        modal.destroy()
      cancel: ->
        modal.destroy()


  notifyPendingInvites = (pendingInvitations, invitations) ->
    pendingInvitations = pendingInvitations.toArray()
    content = "<p><strong>#{pendingInvitations[0].get 'email'}</strong> has already been invited. Are you sure you want to resend invitation?</p>"
    resendButtonText = 'Resend Invitation'
    cancelButtonText = 'Cancel'

    if pendingInvitations.length > 1
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

  notifyAlreadyMemberInvitations = (invitations, resendInvitations, alreadyMemberInvitations) ->

    return handleInvitationRequest invitations, resendInvitations  unless alreadyMemberInvitations.size

    alreadyMembers = alreadyMemberInvitations
      .map (i) -> i.get 'email'
      .toArray()

    content = prepareEmailsText alreadyMemberInvitations.toArray()
    content = "<p>#{content} is already a member of your team.</p>"  if alreadyMembers.length is 1
    content = "<p>#{content} are already members of your team.</p>"  if alreadyMembers.length > 1

    modal = new AlreadyMemberInvitationsModal
      alreadyMembers: alreadyMembers
      content: content
      success: ->
        handleInvitationRequest invitations, resendInvitations
        modal.destroy()


  render: ->

    canEdit = kd.singletons.groupsController.canEditGroup()

    <View
      ref='view'
      canEdit={canEdit}
      inputValues={@state.inputValues}
      onUploadCSV={@bound 'onUploadCSV'}
      onInputChange={@bound 'onInputChange'}
      onInputEmailBlur={@bound 'onInputEmailBlur'}
      onSendInvites={@bound 'onSendInvites'} />


HomeTeamSendInvitesContainer.include [KDReactorMixin]
