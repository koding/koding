class GroupsMemberPermissionsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.type     = 'member'

    super options, data

    data               = @getData()
    list               = @getDelegate()
    {roles, userRoles} = list.getOptions()

    @avatar  = new AvatarView
      size       : width: 30, height: 30
      cssClass   : "avatarview"
      showStatus : yes
    , data

    @profileLink       = new ProfileLinkView {}, data
    @usersRole         = userRoles[data.getId()]

    @userRole          = new KDCustomHTMLView
      partial          : "Roles: " + @usersRole.join ', '
      cssClass         : 'user-numbers'

    if 'owner' in @usersRole or KD.whoami().getId() is data.getId()
      @editLink        = new KDCustomHTMLView "hidden"
    else
      @editLink        = new CustomLinkView
        title          : 'Edit'
        cssClass       : 'fr edit-link'
        icon           :
          cssClass     : 'edit'
        click          : (event)=>
          event.stopPropagation()
          event.preventDefault()
          @showEditMemberRolesView()

    @cancelLink        = new CustomLinkView
      title            : 'Cancel'
      cssClass         : 'fr hidden cancel-link'
      icon             :
        cssClass       : 'delete'
      click            : (event)=>
        event.stopPropagation()
        event.preventDefault()
        @hideEditMemberRolesView()

    @editContainer     = new KDView
      cssClass         : 'edit-container hidden'

    list.on "EditMemberRolesViewShown", (listItem)=>
      if listItem isnt @
        @hideEditMemberRolesView()

    @on 'OwnershipChanged', =>
      @getDelegate().unsetClass 'item-editing'

  showEditMemberRolesView:->

    list           = @getDelegate()
    editorsRoles   = list.getOptions().editorsRoles
    {group, roles, userStatus} = list.getOptions()
    {nickname} = @getData().profile

    @editView      = new GroupsMemberRolesEditView delegate : @
    @editView.setMember @getData()
    @editView.setGroup group

    if group.slug is "koding"
      @editView.setStatus userStatus[nickname]
      
      @editView.on "UserConfirmed", (user)-> 
        userStatus[user.profile.nickname] = "confirmed"

    list.emit "EditMemberRolesViewShown", this

    @setClass 'editing'
    @getDelegate().setClass 'item-editing clearfix'
    @editLink.hide()
    @cancelLink.show()
    @editContainer.show()
    @editContainer.addSubView @editView

    unless editorsRoles
      group.fetchMyRoles (err, editorsRoles)=>
        if err
          log err
        else
          list.getOptions().editorsRoles = editorsRoles
          @editView.setRoles editorsRoles, roles
          @editView.addViews()
    else
      @editView.setRoles editorsRoles, roles
      @editView.addViews()

  hideEditMemberRolesView:->

    @unsetClass 'editing'
    @getDelegate().unsetClass 'item-editing'
    @editLink.show()
    @cancelLink.hide()
    @editContainer.hide()
    @editContainer.destroySubViews()

  viewAppended:JView::viewAppended

  updateRoles:(roles)->
    roles.push 'member'
    @usersRole = roles
    @userRole.updatePartial 'Roles: ' + @usersRole.join ', '

  pistachio:->
    """
      {{> @avatar}}
      {{> @editLink}}
      {{> @cancelLink}}
      {{> @profileLink}}
      {{> @userRole}}
      {{> @editContainer}}
    """
