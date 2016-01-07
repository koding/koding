whoami = require 'app/util/whoami'
MembersListItemView = require 'app/commonviews/memberslistitemview'


module.exports = class GroupMembersPageListItemView extends MembersListItemView
  constructor : (options = {}, data) ->
    options.cssClass     = "clearfix"
    options.avatar       =
      size               :
        width            : 50
        height           : 50

    super options, data

