AvatarView = require './avatarview'


module.exports = class AvatarStaticView extends AvatarView

  constructor: (options = {}, data) ->

    options.tagName or= 'span'

    super options, data

  click: -> yes
