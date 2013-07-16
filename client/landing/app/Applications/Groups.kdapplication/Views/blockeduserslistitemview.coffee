class GroupsBlockedUserListItemView extends KDListItemView

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

    @blockedUntil      = new KDCustomHTMLView
      partial          : "BlockedUntil: " + @data.blockedUntil
      cssClass         : ''

    @unblockButton   = new KDButtonView
      title          : "Unblock"
      callback       : =>
        @blockUser @getData().getId(), '1S', (err, res)=>
          if err
            warn err
          else
            new KDNotificationView title : "User is unblocked!"
            @hide()

    list.on "EditMemberRolesViewShown", (listItem)=>
      if listItem isnt @
        @hideEditMemberRolesView()

  blockUser:(accountId, duration, callback)->
    KD.whoami().blockUser accountId, duration, callback

  hideEditMemberRolesView:->
    @unsetClass 'editing'

  viewAppended:JView::viewAppended

  updateRoles:(roles)->
    roles.push 'member'
    @usersRole = roles
    @userRole.updatePartial 'Roles: ' + @usersRole.join ', '


  pistachio:->
    """
    <div class="kdlistitemview-member-item-inner">
      <section>
        <span class="avatar">{{> @avatar}}</span>
        {{> @profileLink}}
        {{> @userRole}}
        {{> @blockedUntil}}
        {{> @unblockButton}}
      </section>
    </div>
    """
