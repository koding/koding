kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
KDNotificationView = kd.NotificationView
whoami = require 'app/util/whoami'
ProfileTextView = require 'app/commonviews/linkviews/profiletextview'
JView = require 'app/jview'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'


module.exports = class GroupsBlockedUserListItemView extends KDListItemView

  JView.mixin @prototype

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
        whoami().unblockUser @getData().getId(), (err)=>
          if err
            kd.warn err
          else
            new KDNotificationView title : "User is unblocked!"
            @hide()

    list.on "EditMemberRolesViewShown", (listItem)=>
      if listItem isnt this
        @hideEditMemberRolesView()

  blockUser:(accountId, duration, callback)->
    whoami().blockUser accountId, duration, callback

  hideEditMemberRolesView:->
    @unsetClass 'editing'

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


