class GroupMembersPageListItemView extends MembersListItemView
  constructor : (options = {}, data) ->
    options.cssClass     = "clearfix"
    options.avatar       =
      size               :
        width            : 50
        height           : 50

    super options, data

    unless data.getId() is KD.whoami().getId()
      @followButton = new FollowButton
        style          : "solid green medium"
        title          : "follow"
        cssClass       : "follow-button"
        stateOptions   :
          unfollow     :
            title      : "following"
            cssClass   : "solid light-gray medium"
          following    :
            title      : "unfollow"
            cssClass   : "solid red medium"
        dataType       : 'JAccount'
      , data

      @followButton.unsetClass 'follow-btn'
