whoami = require '../util/whoami'
kd = require 'kd'
KDListItemView = kd.ListItemView
AvatarView = require './avatarviews/avatarview'
JCustomHTMLView = require '../jcustomhtmlview'
ProfileLinkView = require './linkviews/profilelinkview'


module.exports = class MembersListItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type        = "member"
    options.avatar     ?=
      size              :
        width           : 40
        height          : 40

    super options, data

    data = @getData()

    avatarSize = @getOption('avatar').size

    @avatar  = new AvatarView
      size       : width: avatarSize.width, height: avatarSize.height
      cssClass   : "avatarview"
    , data

    @actor = new ProfileLinkView {}, data

  viewAppended:->
    @addSubView @avatar
    @addSubView @actor
