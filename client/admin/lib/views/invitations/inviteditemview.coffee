kd                = require 'kd'
JView             = require 'app/jview'
KDButtonView      = kd.ButtonView
KDTimeAgoView     = kd.TimeAgoView
KDListItemView    = kd.ListItemView
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class InvitedItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    { hash, createdAt } = data

    size             = 40
    defaultAvatarUri = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"

    @avatar      = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatarview'
      attributes :
        src      : "//gravatar.com/avatar/#{hash}?s=#{size}&d=#{defaultAvatarUri}"

    @timeAgoView = new KDTimeAgoView {}, createdAt


  pistachio: ->

    { email, firstName, lastName } = @getData()
    emailMarkup = "<span>#{email}</span>"

    if firstName or lastName
      markup = "#{emailMarkup} - #{firstName or ''} #{lastName or ''}"

    return """
      <div class="details">
        {{> @avatar}}
        <p class="fullname">#{markup or emailMarkup}</p>
      </div>
      {{> @timeAgoView}}
    """
