kd                  = require 'kd'
async               = require 'async'
Promise             = require 'bluebird'
remote              = require('app/remote').getInstance()
showError           = require 'app/util/showError'
InvitationInputView = require 'admin/views/invitations/invitationinputview'
whoami              = require 'app/util/whoami'
Tracker             = require 'app/util/tracker'

module.exports = class HomeTeamSendInvites extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'invite-view', options.cssClass

    super options, data

    @inputViews = []

    @createInformationView()
    @addSubView @inputWrapper = new kd.CustomHTMLView { cssClass: 'input-wrapper' }
    @createInitialInputs()
    @createMainButtons()


  createInitialInputs: ->

    @createInvitationView no, yes, yes
    @createInvitationView no
    @createInvitationView yes


  createInvitationView: (addNewOnInput, setFocus, setAdmin) ->

    view = new InvitationInputView

    if addNewOnInput
      view.email.on 'input', =>

        if view.next and view.email.getValue() is '' and view.next.email.getValue() is ''
          view.next.destroy()
          return view.next = null

        return  if view.next
        view.next = @createInvitationView yes, no

    view.once 'KDObjectWillBeDestroyed', =>
      @inputViews.splice @inputViews.indexOf(view), 1

    @inputWrapper.addSubView view
    if setFocus
      kd.utils.defer -> view.email.setFocus()
    view.admin.setValue yes  if setAdmin
    @inputViews.push view

    return view


  createMainButtons: ->

    @addSubView new kd.ButtonView
      title    : 'INVITE MEMBERS'
      cssClass : 'solid medium green invite-members'
      callback :  =>
        whoami().fetchEmail (err, email) =>
          @inviteMembers email


  inviteMembers: (ownEmail) ->

    invites = []
    admins  = []

    for view in @inputViews
      value = view.email.getValue().trim()

      continue  unless value

      result = if not value then no else view.email.validate()

      if value.toLowerCase() is ownEmail
        showError 'You can not invite yourself!'
        return view.email.setClass 'validation-error'

      if value and not result
        showError 'That doesn\'t seem like a valid email address.'
        return view.email.setClass 'validation-error'

      invites.push invite = view.serialize()
      admins.push invite.email  if invite.role is 'admin'

    Tracker.track Tracker.TEAMS_INVITED_TEAMMEMBERS, {
      invitesCount : invites.length
      adminsCount  : admins.length
    }

    if admins.length
      @notifyAdminInvites invites, admins
    else
      @handleInvitationRequest invites


  notifyAdminInvites: (invites, admins) ->

    title = if admins.length > 1 then "You're adding admins" else "You're adding an admin"
    @confirmModal = modal = new kd.ModalViewWithForms
      title                   : title
      overlay                 : yes
      height                  : 'auto'
      cssClass                : 'admin-invite-confirm-modal'
      tabs                    :
        forms                 :
          confirm             :
            buttons           :
              "That's fine"   :
                itemClass     : kd.ButtonView
                cssClass      : 'confirm'
                style         : 'solid green medium'
                loader        : { color: '#444444' }
                callback      : => @handleInvitationRequest invites
              Cancel          :
                itemClass     : kd.ButtonView
                style         : 'solid medium'
                callback      : -> modal.destroy()
            fields            :
              planDetails     :
                type          : 'hidden'
                nextElement   :
                  planDetails :
                    cssClass  : 'content'
                    itemClass : kd.View
                    partial   : "You're inviting <strong>#{admins.join ', '}</strong> as admin, they will have access to all team settings including your stack scripts (excluding your keys)."

    modal.overlay.setClass 'second-overlay'


  notifyPendingInvites: (pendingInvites, newInvites) ->

    partial = "<strong>#{pendingInvites[0].email}</strong> has already been invited. Are you sure you want to resend invitation?"
    resendButtonText = 'Resend Invitation'
    cancelButtonText = 'Cancel'

    if pendingInvites.length > 1
      emailsText = prepareEmailsText pendingInvites
      partial = "#{emailsText} have already been invited. Are you sure you want to resend invitations?"
      resendButtonText = 'Resend Invitations'
      cancelButtonText = 'Just send the new ones' if newInvites.length

    @resendInvitationConfirmModal = modal = new kd.ModalViewWithForms
      title                   : 'Resend invitation'
      overlay                 : yes
      height                  : 'auto'
      cssClass                : 'admin-invite-confirm-modal'
      tabs                    :
        forms                 :
          confirm             :
            buttons           :
              "#{resendButtonText}" :
                itemClass     : kd.ButtonView
                cssClass      : 'confirm'
                style         : 'solid green medium'
                loader        : { color: '#444444' }
                callback      : => @handleResendInvitations pendingInvites, newInvites
              "#{cancelButtonText}" :
                itemClass     : kd.ButtonView
                style         : 'solid medium'
                callback      : => @sendInvitations newInvites
            fields            :
              planDetails     :
                type          : 'hidden'
                nextElement   :
                  planDetails :
                    cssClass  : 'content'
                    itemClass : kd.View
                    partial   : partial

    modal.overlay.setClass 'second-overlay'


  handleResendInvitations: (pendingInvites, newInvitations) ->

    @resendInvitations pendingInvites, newInvitations
    @sendInvitations newInvitations, pendingInvites
    @closeConfirmModals()


  resendInvitations: (invites, newInvitations) ->

    title    = 'Invitation is resent.'
    title    = 'Invitations are resent.'  if invites.length > 1

    queue = invites.map (invite) -> (next) ->

      remote.api.JInvitation.sendInvitationByCode invite.code, (err) ->
        if err
        then next err
        else next()

    async.series queue, (err) =>

      view.destroy()  for view in @inputViews by -1
      @createInitialInputs()

      duration = 5000
      unless newInvitations.length
        title  = "Invitation is resent to <strong>#{invites[0].email}</strong>"
        title  = 'All invitations are resent.'  if invites.length > 1
        return new kd.NotificationView { title, duration }


  fetchPendingInvitations: (invites) ->

    options = {}

    new Promise (resolve, reject) ->

      remote.api.JInvitation['some'] { status: 'pending' }, options, (err, pendings) ->
        if err
          reject err
          return kd.warn err

        pendingInvitations = []

        if pendings.length
          invites.map (inv, i) ->
            invitations = pendings.filter (pending) -> inv.email is pending.email
            pendingInvitations = pendingInvitations.concat invitations

        resolve { pendingInvitations }


  getNewInvitations: (allInvites, pendings) ->

    pendingEmails  = pendings.map (item) -> item.email
    newInvitations = (invite for invite, i in allInvites when invite.email not in pendingEmails)

    return newInvitations


  sendInvitations: (invites, pendingInvites) ->

    return @closeConfirmModals()  unless invites.length

    remote.api.JInvitation.create { invitations: invites }, (err) =>
      if err
        return new kd.NotificationView
          title    : 'Failed to send some invites, please try again.'
          duration : 5000

      view.destroy()  for view in @inputViews by -1

      @createInitialInputs()

      title = "Invitation is sent to <strong>#{invites.first.email}</strong>"

      if invites.length > 1 or pendingInvites?.length
        title = 'All invitations are sent.'

      new kd.NotificationView
        title    : title
        duration : 5000

      Tracker.track Tracker.TEAMS_SENT_INVITATION for invite in invites

      @closeConfirmModals()
      @emit 'NewInvitationsAdded'


  handleInvitationRequest: (invites) ->

    @confirmModal?.destroy()
    @fetchPendingInvitations(invites).then ({ pendingInvitations }) =>
      if pendingInvitations.length
        newInvitations = @getNewInvitations invites, pendingInvitations
        @notifyPendingInvites pendingInvitations, newInvitations
      else
        @sendInvitations invites


  createInformationView: ->

    @addSubView new kd.CustomHTMLView
      cssClass : 'information'
      partial  : '''
        <p>Invite other teammates to your team. You can change admin rights for your teammates in the Members tab once they accept your invitation.</p>
        <label>Email</label><label>First Name</label><label>Last Name<span>Admin</span></label>
        '''


  closeConfirmModals: ->

    @confirmModal?.destroy()
    @confirmModal = null
    @resendInvitationConfirmModal?.destroy()
    @resendInvitationConfirmModal = null


prepareEmailsText = (pendingInvites) ->
  emails = ''
  len    = pendingInvites.length
  [0...len].forEach (i) ->
    emails += "<strong>#{pendingInvites[i].email}</strong>"
    if i + 2 is len
      emails += ', and '
    else if i + 1 is len
      emails += ''
    else
      emails += ', '

  return emails
