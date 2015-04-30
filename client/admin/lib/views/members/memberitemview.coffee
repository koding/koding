kd                     = require 'kd'
JView                  = require 'app/jview'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'


module.exports = class MemberItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    @avatar = new AvatarView
      size  : width: 40, height : 40
    , @getData()

    @roleLabel = new KDCustomHTMLView
      cssClass : 'role'
      partial  : "Member <span class='settings-icon'></span>"
      click    : =>
        @settings.toggleClass  'hidden'
        @roleLabel.toggleClass 'active'

    @createSettingsView()


  createSettingsView: ->

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'

    @settings.addSubView adminSwitch = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'MAKE ADMIN'

    @settings.addSubView moderatorSwitch = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'MAKE MODERATOR'

    @settings.addSubView makeOwnerButton = new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'MAKE OWNER'

    @settings.addSubView kickButton = new KDButtonView
      cssClass : 'solid compact outline red'
      title    : 'KICK USER'


  pistachio: ->
    data     = @getData()
    fullname = getFullnameFromAccount data
    nickname = data.profile.nickname
    email    = "#{nickname}@koding.com"
    role     = 'Member'

    return """
      <div class="details">
        {{> @avatar}}
        <p class="fullname">#{fullname}</p>
        <p class="nickname">@#{nickname}</p>
      </div>
      <p class="email">#{email}</p>
      {{> @roleLabel}}
      <div class='clear'></div>
      {{> @settings}}
    """
