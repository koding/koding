class GroupsMemberPermissionsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = 'formline clearfix'
    options.type     = 'member-item'

    super options, data

    data               = @getData()
    list               = @getDelegate()
    {roles, userRoles} = list.getOptions()
    @avatar            = new AvatarStaticView {}, data
    @profileLink       = new ProfileTextView {}, data
    @usersRole         = userRoles[data.getId()]

    @userRole          = new KDCustomHTMLView
      partial          : "Roles: "+@usersRole
      cssClass         : 'ib role'

    @editLink          = new CustomLinkView
      title            : 'Edit'
      cssClass         : 'fr edit-link'
      icon             :
        cssClass       : 'edit'
      click            : @bound 'showEditMemberRolesView'

    @saveLink          = new CustomLinkView
      title            : 'Save'
      cssClass         : 'fr hidden save-link'
      icon             :
        cssClass       : 'save'
      click            : =>
        @emit 'RolesChanged', @getData(), @editView.getSelectedRoles()
        @hideEditMemberRolesView()
        log "save"

    @cancelLink        = new CustomLinkView
      title            : 'Cancel'
      cssClass         : 'fr hidden cancel-link'
      icon             :
        cssClass       : 'delete'
      click            : @bound 'hideEditMemberRolesView'

    @editContainer     = new KDView
      cssClass         : 'edit-container hidden'

    list.on "EditMemberRolesViewShown", (listItem)=>
      if listItem isnt @
        @hideEditMemberRolesView()

  showEditMemberRolesView:->

    list           = @getDelegate()
    @editView       = new GroupsMemberRolesEditView delegate : @
    @editView.setMember @getData()
    editorsRoles   = list.getOptions().editorsRoles
    {group, roles} = list.getOptions()
    list.emit "EditMemberRolesViewShown", @

    @editLink.hide()
    @cancelLink.show()
    @saveLink.show()  unless KD.whoami().getId() is @getData().getId()
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

    @editLink.show()
    @cancelLink.hide()
    @saveLink.hide()
    @editContainer.hide()
    @editContainer.destroySubViews()

  viewAppended:JView::viewAppended

  pistachio:->
    """
    <section>
      <span class="avatar">{{> @avatar}}</span>
      {{> @editLink}}
      {{> @saveLink}}
      {{> @cancelLink}}
      {{> @profileLink}}
      {{> @userRole}}
    </section>
    {{> @editContainer}}
    """