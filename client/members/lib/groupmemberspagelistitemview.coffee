whoami = require 'app/util/whoami'
MembersListItemView = require 'app/commonviews/memberslistitemview'
FollowButton = require 'app/commonviews/followbutton'


module.exports = class GroupMembersPageListItemView extends MembersListItemView
  constructor : (options = {}, data) ->
    options.cssClass     = "clearfix"
    options.avatar       =
      size               :
        width            : 50
        height           : 50

    super options, data

    unless data.getId() is whoami().getId()
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
          follow       :
            title      : "follow"
            cssClass   : "solid green medium"
        dataType       : 'JAccount'
      , data

      @followButton.unsetClass 'follow-btn'


