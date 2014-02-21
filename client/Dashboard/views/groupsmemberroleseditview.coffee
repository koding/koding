class GroupsMemberRolesEditView extends JView

  constructor:(options = {}, data)->

    super

    @loader   = new KDLoaderView
      size    :
        width : 22

  setRoles:(editorsRoles, allRoles)->
    allRoles = allRoles.reduce (acc, role)->
      acc.push role.title  unless role.title in ['owner', 'guest', 'member']
      return acc
    , []

    @roles      = {
      usersRole    : @getDelegate().usersRole
      allRoles
      editorsRoles
    }

  setMember:(@member)->

  setGroup:(@group)->

  setStatus:(@status)->

  getSelectedRoles:->
    @checkboxGroup.getValue()

  addViews:->

    @loader.hide()

    isAdmin = 'admin' in @roles.usersRole
    @checkboxGroup = new KDInputCheckboxGroup
      name           : 'user-role'
      cssClassPrefix : 'role-'
      defaultValue   : @roles.usersRole
      checkboxes     : @roles.allRoles.map (role)=>
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
      cssClass : 'solid small green'
      callback : =>
        @getDelegate().emit 'RolesChanged', @getDelegate().getData(), @getSelectedRoles()
        @getDelegate().hideEditMemberRolesView()
        log "save"
    ), '.buttons'

    @addSubView (new KDButtonView
      title    : "Kick"
      cssClass : 'solid small red'
      callback : => @showKickModal()
    ), '.buttons'

    if 'owner' in @roles.editorsRoles
      @addSubView (new KDButtonView
        title    : "Make Owner"
        cssClass : 'solid small'
        callback : => @showTransferOwnershipModal()
      ), '.buttons'

    if @group.slug is "koding" and @status is "unconfirmed"
      @addSubView (confirmButton = new KDButtonView
        title    : "Confirm"
        cssClass : 'solid small'
        callback : =>
          KD.remote.api.JAccount.verifyEmailByUsername @member.profile.nickname, (err) =>
            return KD.showError err  if err
            new KDNotificationView title: 'User confirmed'
            @status = "confirmed"
            @emit 'UserConfirmed', @member
            confirmButton.destroy()
      ), '.buttons'

    @$('.buttons').removeClass 'hidden'

  showTransferOwnershipModal:->
    modal = new GroupsDangerModalView
      action     : 'Transfer Ownership'
      longAction : 'transfer the ownership to this user'
      callback   : =>
        @group.transferOwnership @member.getId(), (err)=>
          return @showErrorMessage err if err
          new KDNotificationView title:'Ownership transferred!'
          @getDelegate().emit 'OwnershipChanged'
          modal.destroy()
    , @group

  showKickModal:->
    modal = new KDModalView
      title          : 'Kick Member'
      content        : "<div class='modalformline'>Are you sure you want to kick this member?</div>"
      height         : 'auto'
      overlay        : yes
      buttons        :
        Kick         :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            @group.kickMember @member.getId(), (err)=>
              return @showErrorMessage err if err
              @getDelegate().destroy()
              modal.buttons.Kick.hideLoader()
              modal.destroy()
        Cancel       :
          style      : "modal-cancel"
          callback   : (event)-> modal.destroy()

  showErrorMessage:(err)-> KD.showError err

  pistachio:->
    """
    {{> @loader}}
    <div class='checkboxes'/>
    <div class='buttons hidden'/>
    """

  viewAppended:->

    super

    @loader.show()
