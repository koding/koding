kd                 = require 'kd'
JView              = require 'app/jview'
remote             = require('app/remote').getInstance()
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

    return  unless @isPendingView()

    @settings.toggleClass 'hidden'
    @toggleClass 'settings-visible'

    return  if @settings.hasClass 'hidden'

    top        = @getElement().offsetTop + 10
    { parent } = @getDelegate() # It references a KDCustomScrollViewWrapper instance
    parent.scrollTo { top, duration : 250 }


  revoke: ->

    return  unless @isPendingView()

    @revokeButton.showLoader()

    @getDelegate().emit 'ItemAction', { action : 'RemoveItem', item : this }


  resend: ->

    return  unless @isPendingView()

    @resendButton.showLoader()

    @getDelegate().emit 'ItemAction', { action : 'Resend', item : this }


  isPendingView: ->

    return  @getOptions().statusType is 'pending'


  createViews: ->

    { hash, createdAt, modifiedAt } = @getData()
    { statusType }      = @getOptions()
    size                = 40
    defaultAvatarUri    = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"

    @avatar      = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatarview'
      attributes :
        src      : "//gravatar.com/avatar/#{hash}?s=#{size}&d=#{defaultAvatarUri}"

    @timeAgoView  = new KDTimeAgoView { click: @bound 'showSettings' }, modifiedAt or createdAt

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
        cssClass : 'solid compact outline revoke-button'
        title    : 'REVOKE INVITATION'
        loader   : { color : '#4a4e52' }
        callback : @bound 'revoke'

      @settings.addSubView @resendButton = new KDButtonView
        cssClass : 'solid compact outline resend-button'
        title    : 'RESEND INVITATION'
        loader   : { color : '#4a4e52' }
        callback : @bound 'resend'


  pistachio: ->

    { email, firstName, lastName } = @getData()
    emailMarkup = "<span title='#{email}' class='email'>#{email}</span>"

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
