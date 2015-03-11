whoami = require '../util/whoami'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDNotificationView = kd.NotificationView
JView = require '../jview'
PopupGroupListItem = require '../popupgrouplistitem'
module.exports = class PopupGroupListItemPending extends PopupGroupListItem

  JView.mixin @prototype

  constructor:(options = {}, data)->
    super

    {group} = @getData()
    @setClass 'role pending'

    @acceptButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Accept Invitation'
      icon        : yes
      iconOnly    : yes
      iconClass   : 'accept'
      tooltip     :
        title     : 'Accept Invitation'
      callback    : =>
        whoami().acceptInvitation group, (err)=>
          if err then kd.warn err
          else
            @destroy()
            @parent.emit 'PendingCountDecreased'
            @parent.emit 'UpdateGroupList'

    @ignoreButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Ignore Invitation'
      icon        : yes
      iconOnly    : yes
      iconClass   : 'ignore'
      tooltip     :
        title     : 'Ignore Invitation'
      callback    : =>
        whoami().ignoreInvitation group, (err)=>
          if err then kd.warn err
          else
            new KDNotificationView
              title    : 'Ignored!'
              content  : 'If you change your mind, you can request access to the group anytime.'
              duration : 2000
            @destroy()
            @parent.emit 'PendingCountDecreased'


  pistachio: ->
    """
    <div class='right-overflow'>
      <div class="buttons">
        {{> @acceptButton}}
        {{> @ignoreButton}}
      </div>
      {{> @switchLink}}
    </div>
    """
