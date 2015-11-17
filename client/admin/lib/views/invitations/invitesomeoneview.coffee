kd                  = require 'kd'
remote              = require('app/remote').getInstance()
KDView              = kd.View
KDButtonView        = kd.ButtonView
KDCustomScrollView  = kd.CustomScrollView
KDCustomHTMLView    = kd.CustomHTMLView
KDNotificationView  = kd.NotificationView
InvitationInputView = require './invitationinputview'
showError           = require 'app/util/showError'


module.exports = class InviteSomeoneView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'invite-view'

    super options, data

    @scrollView = new KDCustomScrollView
    @addSubView @scrollView

    @inputViews = []

    @createInformationView()
    @scrollView.wrapper.addSubView @inputWrapper = new KDCustomHTMLView cssClass: 'input-wrapper'
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

    @addSubView new KDButtonView
      title    : 'INVITE MEMBERS'
      cssClass : 'solid medium green invite-members'
      callback : @bound 'inviteMembers'


  inviteMembers: ->

    invites = []

    for view in @inputViews
      value = view.email.getValue().trim()

      continue  unless value

      result = if not value then no else view.email.validate()

      if value and not result
        showError 'That doesn\'t seem like a valid email address.'
        return view.email.setClass 'validation-error'

      invites.push view.serialize()


    remote.api.JInvitation.create invitations: invites, (err) =>
      if err
        return new KDNotificationView
          title    : 'Failed to send some invites, please try again.'
          duration : 5000

      view.destroy()  for view in @inputViews by -1

      @createInitialInputs()

      new KDNotificationView
        title    : 'Invitations are sent to new members.'
        duration : 5000

      @emit 'NewInvitationsAdded'


  createInformationView: ->

    @scrollView.wrapper.addSubView new KDCustomHTMLView
      cssClass : 'information'
      partial  : """
        <p>Invite other teammates to your team. You can change admin rights for your teammates in the Members tab once they accept your invitation.</p>
        <label>Email</label><label>First Name</label><label>Last Name<span>Admin</span></label>
        """
