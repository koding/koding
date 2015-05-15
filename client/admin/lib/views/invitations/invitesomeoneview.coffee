kd                  = require 'kd'
remote              = require('app/remote').getInstance()
KDView              = kd.View
KDButtonView        = kd.ButtonView
KDCustomHTMLView    = kd.CustomHTMLView
KDNotificationView  = kd.NotificationView
InvitationInputView = require './invitationinputview'


module.exports = class InviteSomeoneView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'invite-view'

    super options, data

    @inputViews = []

    @createInformationView()
    @addSubView @inputWrapper = new KDCustomHTMLView cssClass: 'input-wrapper'
    @createInvitationView no
    @createAddMoreButton()
    @createMainButtons()


  createInvitationView: (cancellable) ->

    view = new InvitationInputView { cancellable }

    view.once 'KDObjectWillBeDestroyed', =>
      @inputViews.splice @inputViews.indexOf(view), 1

    @inputWrapper.addSubView view
    @inputViews.push view


  createAddMoreButton: ->

    @addSubView new KDButtonView
      cssClass : 'compact solid add-more'
      title    : 'ADD INVITATION'
      callback : @bound 'createInvitationView'


  createMainButtons: ->

    @addSubView new KDButtonView
      title    : 'CANCEL'
      cssClass : 'solid medium cancel'
      callback : => @emit 'InvitationViewCancelled'

    @addSubView new KDButtonView
      title    : 'INVITE MEMBERS'
      cssClass : 'solid medium green invite-members'
      callback : @bound 'inviteMembers'


  inviteMembers: ->

    invites = []

    for view in @inputViews
      return unless view.email.validate()

      invites.push view.serialize()


    remote.api.JInvitation.create invitations: invites, (err) =>
      if err
        return new KDNotificationView
          title    : 'Failed to send some invites, please try again.'
          duration : 5000

      for view in @inputViews by -1
        if view.getOptions().cancellable then view.destroy()
        else
          input.setValue ''  for input in view.inputs

      new KDNotificationView
        title    : 'All invites sent.'
        duration : 5000

      @emit 'NewInvitationsAdded'


  createInformationView: ->

    @addSubView new KDCustomHTMLView
      cssClass : 'information'
      partial  : """
        <p>Invite others to join your team. You can also allow team members to sign up using your company's email domain.</p>

        <p>People you invite as full team members have the following capabilities:</p>

        <ul>
          <li>- Create and join any channel on your team</li>
          <li>- Create or be invited to private groups on your team</li>
          <li>- Exchange direct messages with any member of your team</li>
          <li>- Collaborate with other team members</li>
          <li>- Have access to shared resources</li>
          <li>- Provisioning new machines</li>
        </ul>
      """
