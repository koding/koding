class PopupNotificationListItem extends NotificationListItem

  constructor:(options = {}, data)->
    options.tagName        or= "li"
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView
    super options, data
    @initializeReadState()

  initializeReadState:->
    if @getData().glanced
    then @unsetClass 'unread'
    else @setClass 'unread'

  pistachio:->
    """
      {{> @avatar}}
      <div class="fr">
        {{> @participants}}
        {{@getActionPhrase #(dummy)}}
        {{> @activityPlot}}
        {{> @interactedGroups}}
        {time{$.timeago @getLatestTimeStamp #(dummy)}}
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

    super event
