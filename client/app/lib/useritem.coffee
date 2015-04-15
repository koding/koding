kd = require 'kd'
KDListItemView = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView
AvatarView = require 'app/commonviews/avatarviews/avatarview'


module.exports = class UserItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.type           = 'user'
    options.justFirstName ?= yes

    super options, data


  viewAppended: ->

    { profile: { firstName, lastName, nickname} } = @getData()

    { size, justFirstName } = @getOptions()

    name = if justFirstName then firstName else "#{firstName} #{lastName}"

    @avatar    = new AvatarView
      origin   : nickname
      size     : size or width: 22, height: 22

    @name      = new KDCustomHTMLView
      cssClass : 'name'
      partial  : name

    @addSubView @avatar
    @addSubView @name

    @addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'remove'
      click    : =>
        @getDelegate().emit 'KickUserRequested', this
