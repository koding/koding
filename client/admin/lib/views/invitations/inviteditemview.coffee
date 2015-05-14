kd                 = require 'kd'
JView              = require 'app/jview'
KDButtonView       = kd.ButtonView
KDTimeAgoView      = kd.TimeAgoView
KDListItemView     = kd.ListItemView
KDCustomHTMLView   = kd.CustomHTMLView
KDNotificationView = kd.NotificationView


module.exports = class InvitedItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     or= 'member'
    options.cssClass   = options.statusType

    super options, data

    @createViews()


  showSettings: ->

    @settings.toggleClass 'hidden'
    @toggleClass 'settings-visible'


  revoke: ->

    return  unless @getOptions().statusType is 'pending'

    @revokeButton.showLoader()

    @getData().remove (err) =>
      return @destroy()  unless err

      @revokeButton.hideLoader()
      new KDNotificationView
        title    : 'Unable to revoke invitation. Please try again.'
        duration : 5000


  createViews: ->

    { hash, createdAt } = @getData()
    { statusType }      = @getOptions()
    size                = 40
    defaultAvatarUri    = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"

    @avatar      = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatarview'
      attributes :
        src      : "//gravatar.com/avatar/#{hash}?s=#{size}&d=#{defaultAvatarUri}"

    @timeAgoView  = new KDTimeAgoView { click: @bound 'showSettings' }, createdAt

    if statusType is 'pending'
      @settingsIcon = new KDCustomHTMLView
        tagName     : 'span'
        cssClass    : 'settings-icon'
        click       : @bound 'showSettings'
    else
      @settingsIcon = new KDCustomHTMLView

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'

    if statusType is 'pending'

      @settings.addSubView @revokeButton = new KDButtonView
        cssClass : 'solid compact outline'
        title    : 'REVOKE INVITATION'
        loader   : color : '#4a4e52'
        callback : @bound 'revoke'

      @settings.addSubView new KDButtonView
        cssClass : 'solid compact outline'
        title    : 'RESEND INVITATION'


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
      {{> @settingsIcon}}
      <div class="clear"></div>
      {{> @settings}}
    """
