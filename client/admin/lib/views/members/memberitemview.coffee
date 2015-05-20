kd                     = require 'kd'
JView                  = require 'app/jview'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'

# a user be a Member, Admin and Owner at the same time but in the UI we should
# show the role name which has the most permissions.
defaultRoles =
  guest      : nicename : 'Guest',     priority : 0
  member     : nicename : 'Member',    priority : 1
  moderator  : nicename : 'Moderator', priority : 2
  admin      : nicename : 'Admin',     priority : 3
  owner      : nicename : 'Owner',     priority : 4


module.exports = class MemberItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    @memberRole       = @getRole data.roles

    @avatar = new AvatarView
      size  : width: 40, height : 40
    , @getData()

    @roleLabel = new KDCustomHTMLView
      cssClass : 'role'
      partial  : "#{@memberRole.label} <span class='settings-icon'></span>"
      click    : @bound 'toggleSettings'

    @createSettingsView()



  getRole: (userRoles) ->

    currentRole = defaultRoles.member

    # find the most prioritized role
    for userRole in userRoles when role = defaultRoles[userRole]
      currentRole = role  if role.priority > currentRole.priority

    return currentRole


  createSettingsView: ->

    userRoles = @getData().roles

    @settings  = new KDCustomHTMLView
      cssClass : 'settings hidden'

    @settings.addSubView new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'MAKE ADMIN'

    @settings.addSubView new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'MAKE MODERATOR'

    @settings.addSubView new KDButtonView
      cssClass : 'solid compact outline'
      title    : 'MAKE OWNER'
  toggleSettings: ->

    @settings.addSubView new KDButtonView
      cssClass : 'solid compact outline red'
      title    : 'KICK USER'
    @settings.toggleClass  'hidden'
    @roleLabel.toggleClass 'active'


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
