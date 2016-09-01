kd = require 'kd'
KDButtonView = kd.ButtonView
KDInputCheckboxGroup = kd.InputCheckboxGroup
KDLoaderView = kd.LoaderView
KDModalView = kd.ModalView
KDNotificationView = kd.NotificationView
GroupsDangerModalView = require './groupsdangermodalview'
remote = require 'app/remote'
showError = require 'app/util/showError'
JView = require 'app/jview'
$ = require 'jquery'


module.exports = class GroupsMemberRolesEditView extends JView

  constructor: (options = {}, data) ->

    super

    @loader   = new KDLoaderView
      size    :
        width : 22

  setRoles: (editorsRoles, allRoles) ->
    allRoles = allRoles.reduce (acc, role) ->
      acc.push role.title  unless role.title in ['owner', 'guest', 'member']
      return acc
    , []

    @roles      = {
      usersRole    : @getDelegate().usersRole
      allRoles
      editorsRoles
    }

  setMember: (@member) ->

  setGroup: (@group) ->

  setStatus: (@status) ->

  getSelectedRoles: ->
    @checkboxGroup.getValue()

  addViews: ->

    @loader.hide()

    isAdmin = 'admin' in @roles.usersRole
    @checkboxGroup = new KDInputCheckboxGroup
      name           : 'user-role'
      cssClassPrefix : 'role-'
      defaultValue   : @roles.usersRole
      checkboxes     : @roles.allRoles.map (role) =>
        if role is 'admin'
          callback = =>
            isAdmin = 'admin' in @checkboxGroup.getValue()
            for el in @checkboxGroup.getInputElements()
              el = $(el)
              if el.val() isnt 'admin'
                if isAdmin
                  el.removeAttr 'checked'
                  el.parent().hide()
                else
                  el.parent().show()
        else
          callback = ->

        value      : role
        title      : role.capitalize()
        visible    : if role isnt 'admin' and isAdmin then no else yes
        callback   : callback

    @addSubView @checkboxGroup, '.checkboxes'

    @addSubView (new KDButtonView
      title    : 'Save'
      style    : 'solid small green'
      callback : =>
        @getDelegate().emit 'RolesChanged', @getDelegate().getData(), @getSelectedRoles()
        @getDelegate().hideEditMemberRolesView()
        kd.log 'save'
    ), '.buttons'

    @addSubView (new KDButtonView
      title    : 'Kick'
      style    : 'solid small red'
      callback : => @showKickModal()
    ), '.buttons'

    if 'owner' in @roles.editorsRoles
      @addSubView (new KDButtonView
        title    : 'Make Owner'
        style    : 'solid small'
        callback : => @showTransferOwnershipModal()
      ), '.buttons'

    if @group.slug is 'koding' and @status is 'unconfirmed'
      @addSubView (confirmButton = new KDButtonView
        title    : 'Confirm'
        style    : 'solid small'
        callback : =>
          remote.api.JAccount.verifyEmailByUsername @member.profile.nickname, (err) =>
            return showError err  if err
            new KDNotificationView { title: 'User confirmed' }
            @status = 'confirmed'
            @emit 'UserConfirmed', @member
            confirmButton.destroy()
      ), '.buttons'

    @$('.buttons').removeClass 'hidden'

  showTransferOwnershipModal: ->
    modal = new GroupsDangerModalView
      action     : 'Transfer Ownership'
      longAction : 'transfer the ownership to this user'
      callback   : =>
        @group.transferOwnership @member.getId(), (err) =>
          return @showErrorMessage err if err
          new KDNotificationView { title: 'Ownership transferred!' }
          @getDelegate().emit 'OwnershipChanged'
          modal.destroy()
    , @group

  showKickModal: ->
    modal = new KDModalView
      title          : 'Kick Member'
      content        : "<div class='modalformline'>Are you sure you want to kick this member?</div>"
      height         : 'auto'
      overlay        : yes
      buttons        :
        Kick         :
          style      : 'solid red medium'
          loader     :
            color    : '#444444'
          callback   : =>
            @group.kickMember @member.getId(), (err) =>
              return @showErrorMessage err if err
              @getDelegate().destroy()
              modal.buttons.Kick.hideLoader()
              modal.destroy()
        Cancel       :
          style      : 'solid light-gray medium'
          callback   : (event) -> modal.destroy()

  showErrorMessage: (err) -> showError err

  pistachio: ->
    """
    {{> @loader}}
    <div class='checkboxes'/>
    <div class='buttons hidden'/>
    """

  viewAppended: ->

    super

    @loader.show()
