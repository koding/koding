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
      partial          : "Roles: " + @usersRole.join ', '
      cssClass         : 'ib role'

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

  showEditMemberRolesView:->

    list           = @getDelegate()
    editorsRoles   = list.getOptions().editorsRoles
    {group, roles} = list.getOptions()

    @editView      = new GroupsMemberRolesEditView delegate : @
    @editView.setMember @getData()
    @editView.setGroup group

    list.emit "EditMemberRolesViewShown", this

    @setClass 'editing'
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
    @editLink.show()
    @cancelLink.hide()
    @editContainer.hide()
    @editContainer.destroySubViews()

  viewAppended:JView::viewAppended

  pistachio:->
    """
    <div class="kdlistitemview-member-item-inner">
      <section>
        <span class="avatar">{{> @avatar}}</span>
        {{> @editLink}}
        {{> @cancelLink}}
        {{> @profileLink}}
        {{> @userRole}}
      </section>
      {{> @editContainer}}
    </div>
    """