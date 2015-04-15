kd = require 'kd'
KDListItemView = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView
AvatarView = require 'app/commonviews/avatarviews/avatarview'


module.exports = class UserItem extends KDListItemView

  constructor: (options = {}, data)->

    options.type = 'user'
    super options, data

  viewAppended: ->

    {profile:{firstName, nickname}} = @getData()

    @avatar    = new AvatarView
      origin   : nickname
      size     : @getOptions().size or width: 22, height: 22

    @name = new KDCustomHTMLView
      cssClass : 'name'
      partial  : firstName

    @addSubView @avatar
    @addSubView @name
    @addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'remove'
      click    : =>
        @getDelegate().emit 'KickUserRequested', this
