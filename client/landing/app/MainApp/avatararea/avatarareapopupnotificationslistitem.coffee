class PopupNotificationListItem extends NotificationListItem

  constructor:(options = {}, data)->

    options.tagName        or= "li"
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView

    super options, data

    @initializeReadState()

  initializeReadState:->
    if @getData().getFlagValue('glanced')
      @unsetClass 'unread'
    else
      @setClass 'unread'

  pistachio:->
    """
      <span class='icon notification-type'></span>
      <span class='avatar'>{{> @avatar}}</span>
      <div class='right-overflow'>
        <p>{{> @participants}} {{@getActionPhrase #(dummy)}} {{@getActivityPlot #(dummy)}}</p>
        <footer>
          <time>{{$.timeago @getLatestTimeStamp #(dummy)}}</time>
        </footer>
      </div>
    """

  click:(event)->

    popupList = @getDelegate()
    popupList.emit 'AvatarPopupShouldBeHidden'

    # If we need to use implement click to mark as read for notifications
    # Just un-comment following 3 line. A friend from past.
    # {_id} = @getData()
    # KD.whoami().glanceActivities _id, (err)=>
    #   if err then log "Error: ", err

    super